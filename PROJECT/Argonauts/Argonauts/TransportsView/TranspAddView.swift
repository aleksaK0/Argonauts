//
//  TranspAddView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 03.07.2021.
//

import SwiftUI

struct TranspAddView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var isPresented: Bool
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var producted: String = ""
    @State var mileage: String = ""
    @State var engHour: String = ""
    @State var diagDate: Date = Date()
    @State var osagoDate: Date = Date()
    @State var osagoLife: Date = Date()
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showTranspAddNot: Bool = false
    
    @State var isOn1: Bool = false
    @State var isOn2: Bool = false
    @State var isOn3: Bool = false
    @State var isOn4: Bool = false
    @State var isOn5: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                Text("Обязательное поле")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .padding([.top])
                TextField("Ник", text: $nick)
                    .disableAutocorrection(true)
                    .padding([.leading, .trailing])
                Text("Дополнительные поля")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                TextField("Год выпуска", text: $producted)
                    .keyboardType(.numberPad)
                    .padding([.leading, .trailing])
                TextField("Текущий пробег", text: $mileage)
                    .keyboardType(.numberPad)
                    .padding([.leading, .trailing])
                TextField("Моточасы", text: $engHour)
                    .keyboardType(.numberPad)
                    .padding([.leading, .trailing])
                HStack {
                    Text("Дата диаг. карты")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                    Spacer()
                    Toggle("", isOn: $isOn4)
                        .labelsHidden()
                }
                .padding([.leading, .trailing])
                DatePicker("", selection: $diagDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .disabled(!isOn4)
                HStack {
                    Text("Дата ОСАГО")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                    Spacer()
                    Toggle("", isOn: $isOn5)
                        .labelsHidden()
                }
                .padding([.leading, .trailing])
                DatePicker("", selection: $osagoDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .disabled(!isOn5)
            }
            if isLoading {
                Rectangle()
                    .fill(Color.loadingColor.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .alert(isPresented: $showAlert) {
            if alertMessage == "Добавить уведомления?" {
                return Alert(title: Text("Уведомления"),
                             message: Text(alertMessage),
                             primaryButton: .default(Text("Позже")) {
                                isPresented = false
                             },
                             secondaryButton: .default(Text("Добавить")) {
                                showTranspAddNot = true
                             }
                )
            } else {
                return Alert(title: Text("Ошибка"), message: Text(alertMessage))
            }
        }
        .fullScreenCover(isPresented: $showTranspAddNot, content: {
            NavigationView {
                TranspAddNotification(tid: tid, nick: nick, isPresented: $isPresented, showTranspAddNot: $showTranspAddNot)
                    .environmentObject(globalObj)
            }
        })
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Добавление", displayMode: .inline)
        .navigationBarItems(
            leading:
                Button(action: {
                    isPresented = false
                }, label: {
                    Text("Отм.")
                }),
            trailing:
                Button(action: {
                    addTranspAsync()
                }, label: {
                    Text("Доб.")
                })
                .disabled(nick.isEmpty)
        )
    }
    
    func isValidNick(nick: String) -> Bool {
        do {
            let regEx = "^[A-Za-z0-9._]{1,16}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = nick as NSString
            let results = regex.matches(in: nick, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                 return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    func isValidMileage(mileage: String) -> Bool {
        do {
            let regEx = "^[0-9]{1,9}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = mileage as NSString
            let results = regex.matches(in: mileage, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
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
    
    func canAddTransp() -> Bool {
        if (producted.isEmpty || isValidYear(year: producted)) && (mileage.isEmpty || isValidMileage(mileage: mileage)) && (engHour.isEmpty || isValidEngHour(engHour: engHour)) && isValidNick(nick: nick) {
            return true
        } else {
            return false
        }
    }
    
    func addTranspAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if canAddTransp() {
                var diagDateFormatted = ""
                var osagoDateFormatted = ""
                if isOn4 {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "ru")
                    formatter.dateFormat = "YYYY-MM-dd"
                    diagDateFormatted = formatter.string(from: diagDate)
                }
                if isOn5 {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "ru")
                    formatter.dateFormat = "YYYY-MM-dd"
                    osagoDateFormatted = formatter.string(from: osagoDate)
                }
                addTransp(email: globalObj.email, nick: nick, producted: producted, mileage: mileage, engHour: engHour, diagDate: diagDateFormatted, osagoDate: osagoDateFormatted)
                if alertMessage == "" {
                    if isOn4 {
                        addNotification(tid: String(tid), dataType: "D", mode: "1", date: diagDate, value1: "", value2: "", notification: "Истекает срок действия диагностической карты")
                    }
                    if isOn5 {
                        addNotification(tid: String(tid), dataType: "D", mode: "2", date: osagoDate, value1: "", value2: "", notification: "Истекает срок действия полиса ОСАГО")
                    }
                }
            } else {
                alertMessage = "Введены некорректные данные"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    alertMessage = "Добавить уведомления?"
                    showAlert = true
                }
                isLoading = false
            }
        }
    }
    
    func addNotification(tid: String, dataType: String, mode: String, date: Date, value1: String, value2: String, notification: String) {
        var dateComponent = DateComponents()
        dateComponent.day = 335
        let dateExp = Calendar.current.date(byAdding: dateComponent, to: date)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateExp ?? Date())
        
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_notification&tid=" + tid + "&type=" + dataType + "&mode=" + mode + "&date=" + dateString + "&notification=" + notification
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
    
    func addTransp(email: String, nick: String, producted: String, mileage: String, engHour: String, diagDate: String, osagoDate: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_transp&email=" + email + "&nick=" + nick + "&producted=" + producted + "&mileage=" + mileage + "&eng_hour=" + engHour + "&diag_date=" + diagDate + "&osago_date=" + osagoDate
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_transp"] as! [String : Any]
                    print("TranspAddView.addTransp(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Транспортное средство с таким ником уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера, попробуйте ещё раз позже"
                            showAlert = true
                        }
                    } else if info["mileage"] != nil {
                        let dop = info["mileage"] as! [String : Any]
                        if dop["server_error"] != nil {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["eng_hour"] != nil {
                        let dop = info["eng_hour"] as! [String : Any]
                        if dop["server_error"] != nil {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else {
                        alertMessage = ""
                        tid = info["tid"] as! Int
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
