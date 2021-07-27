//
//  EngHourDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 09.07.2021.
//

import SwiftUI

struct EngHourDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    @State var engHour: String = ""
    @State var date: Date = Date()
    @State var engHours: [EngHour] = []
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    TextField("Моточасы", text: $engHour)
                        .keyboardType(.numberPad)
                        .padding([.leading, .trailing])
                    Button {
                        UIApplication.shared.endEditing()
                        addEngHourAsync()
                    } label: {
                        Text("Добавить")
                    }
                    .disabled(engHour.isEmpty)
                    .padding([.top])
                }
                if engHours.isEmpty {
                    Text("Здесь будет список записей о моточасах")
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(engHours, id: \.ehid) { engHour in
                            HStack {
                                Text(engHour.date)
                                Spacer()
                                Text("\(engHour.engHour)")
                            }
                        }
                        .onDelete(perform: deleteEngHourAsync)
                    }
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.loadingColor.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .navigationBarTitle(nick, displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    showFields.toggle()
                                }, label: {
                                    if showFields {
                                        Image(systemName: "minus")
                                            .font(.title2.weight(.semibold))
                                    } else {
                                        Image(systemName: "plus")
                                            .font(.title2.weight(.semibold))
                                    }
                                }))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getEngHourAsync()
        }
    }
    
    func getEngHourAsync() {
        isLoading = true
        engHours = []
        DispatchQueue.global(qos: .userInitiated).async {
            getEngHour(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func addEngHourAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if isValidEngHour(engHour: engHour) {
                addEngHour(tid: String(tid), date: date, engHour: engHour)
            } else {
                alertMessage = "Введено некорректное значение"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    engHour = ""
                }
                isLoading = false
            }
        }
    }
    
    func deleteEngHourAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let ehid = engHours[index].ehid
            deleteEngHour(ehid: String(ehid), tid: String(tid))
            DispatchQueue.main.async {
                if alertMessage == "" {
                    engHours.remove(at: index)
                }
                isLoading = false
            }
        }
    }
    
    func isValidEngHour(engHour: String) -> Bool {
        do {
            let regEx = "^[0-9]{1,9}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = engHour as NSString
            let results = regex.matches(in: engHour, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                 return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    func getEngHour(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_eng_hour&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_eng_hour"] as! [[String : Any]]
                    print("EngHourDetailView.getEngHour(): \(info)")
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            date = reverseDateTime(date: date)
                            
                            let engHour = EngHour(ehid: el["ehid"] as! Int, date: date, engHour: el["eng_hour"] as! Int)
                            engHours.append(engHour)
                        }
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
    
    func addEngHour(tid: String, date: Date, engHour: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_eng_hour&tid=" + tid + "&date=" + dateString + "&eng_hour=" + engHour
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_eng_hour"] as! [String : Any]
                    print("EngHourDetailView.addEngHour(): \(info)")
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["ehid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        let date = reverseDateTime(date: dateString)
                        engHours.append(EngHour(ehid: info["ehid"] as! Int, date: date, engHour: info["eng_hour"] as! Int))
                        engHours.sort { $0.date > $1.date }
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
    
    func deleteEngHour(ehid: String, tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_eng_hour&ehid=" + ehid + "&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_eng_hour"] as! [String : Any]
                    print("EngHourDetailView.deleteEngHour(): \(info)")
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
}
