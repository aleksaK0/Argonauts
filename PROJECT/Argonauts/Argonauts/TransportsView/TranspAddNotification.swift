//
//  TranspAddNotification.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 19.07.2021.
//

import SwiftUI

struct TranspAddNotification: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    @Binding var isPresented: Bool
    @Binding var showTranspAddNot: Bool
    
    @State var alertMessage: String = ""
    @State var type: String = "Дата"
    @State var notification: String = ""
    @State var date: Date = Date()
    @State var value1: String = ""
    @State var value2: String = ""
    @State var types: [String] = ["Дата", "Пробег", "Топливо", "Моточасы"]
    @State var notifications: [Notification] = []
    
    @State var isExpanded: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                DisclosureGroup("Критерий: \(type)", isExpanded: $isExpanded) {
                    ForEach(types, id: \.self) { el in
                        HStack {
                            Spacer()
                            Text(el)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            type = el
                            isExpanded = false
                        }
                        Divider()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.toggle()
                }
                .padding([.leading, .trailing])
                TextField("Уведомление", text: $notification)
                    .disableAutocorrection(true)
                    .padding([.leading, .trailing])
                switch type {
                case "Дата":
                    DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                case "Топливо":
                    TextField(type, text: $value1)
                        .keyboardType(.numberPad)
                        .padding([.leading, .trailing])
                default:
                    TextField(type + " (наступление)", text: $value1)
                        .keyboardType(.numberPad)
                        .padding([.leading, .trailing])
                    TextField(type + " (приближение (доп))", text: $value2)
                        .keyboardType(.numberPad)
                        .padding([.leading, .trailing])
                }
                Button(action: {
                    UIApplication.shared.endEditing()
                    addNotificationAsync()
                }, label: {
                    Text("Добавить")
                })
                .disabled(notification.isEmpty || (type != "Дата" && value1.isEmpty))
                if notifications.isEmpty {
                    Text("Здесь будет список уведомлений")
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(notifications, id: \.nid) { notification in
                            RowNotification(notification: notification)
                        }
                        .onDelete(perform: deleteNotificationAsync)
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
        .navigationBarItems(leading:
                                Button(action: {
                                    showTranspAddNot = false
                                    isPresented = false
                                }, label: {
                                    Text("Отм.")
                                }),
                            trailing:
                                Button(action: {
                                    showTranspAddNot = false
                                    isPresented = false
                                }, label: {
                                    Text("Готово")
                                })
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getNotificationAsync()
        }
    }
    
    func isValidValue(value: String) -> Bool {
        do {
            let regEx = "^[0-9]{1,9}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = value as NSString
            let results = regex.matches(in: value, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    func canAddNotification(type: String) -> Bool {
        if type == "Дата" {
            return true
        } else if type == "Моточасы" || type == "Пробег" {
            if isValidValue(value: value1) {
                if value2.isEmpty == false {
                    if isValidValue(value: value2) && Int(value1)! > Int(value2)! {
                        return true
                    }
                } else {
                    return true
                }
            }
        } else if type == "Топливо" {
            if isValidValue(value: value1) {
                return true
            }
        }
        return false
    }
    
    func getNotificationAsync() {
        isLoading = true
        notifications = []
        DispatchQueue.global(qos: .userInitiated).async {
            getNotification(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func addNotificationAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if canAddNotification(type: type) {
                addNotification(tid: String(tid), dataType: type, mode: "0", date: date, value1: value1, value2: value2, notification: notification)
            } else {
                alertMessage = "Введены некорректные данные"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    notification = ""
                    value1 = ""
                    value2 = ""
                }
                isLoading = false
            }
        }
    }
    
    func deleteNotificationAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let nid = notifications[index].nid
            deleteNotification(nid: String(nid))
            DispatchQueue.main.async {
                if alertMessage == "" {
                    notifications.remove(at: index)
                }
                isLoading = false
            }
        }
    }
    
    func getNotification(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_notification&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_notification"] as! [[String : Any]]
                    print("ServiceMaterialView.getNotification(): \(info)")
                    
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            let notification = Notification(nid: el["nid"] as! Int, tid: el["tid"] as! Int, type: el["type"] as! String, mode: el["mode"] as! Int, date: el["date"] as? String, value1: el["value1"] as? Int, value2: el["value2"] as? Int, notification: el["notification"] as! String)
                            notifications.append(notification)
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
    
    func addNotification(tid: String, dataType: String, mode: String, date: Date, value1: String, value2: String, notification: String) {
        var type: String = ""
        var dateString = ""
        
        switch dataType {
        case "Дата":
            type = "D"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru")
            formatter.dateFormat = "yyyy-MM-dd"
            dateString = formatter.string(from: date)
        case "Пробег":
            type = "M"
        case "Топливо":
            type = "F"
        case "Моточасы":
            type = "H"
        default:
            type = ""
        }
        
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_notification&tid=" + tid + "&type=" + type + "&mode=" + mode + "&date=" + dateString + "&value1=" + value1 + "&value2=" + value2 + "&notification=" + notification
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_notification"] as! [String : Any]
                    print("ServiceMaterialView.addNotification(): \(info)")
                    
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        notifications.append(Notification(nid: info["nid"] as! Int, tid: info["tid"] as! Int, type: info["type"] as! String, mode: info["mode"] as! Int, date: info["date"] as? String, value1: info["value1"] as? Int, value2: info["value2"] as? Int, notification: info["notification"] as! String))
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
    
    func deleteNotification(nid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_notification&nid=" + nid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_notification"] as! [String : Any]
                    print("ServiceMaterialView.deleteMaterial(): \(info)")
                    
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
