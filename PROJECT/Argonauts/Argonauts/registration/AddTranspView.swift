//
//  AddCarRequiredView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 28.06.2021.
//

import SwiftUI

struct AddTranspView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var alertMessage: String = ""
    @State var showOptional: Bool = false
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showTranspAddNot: Bool = false
    
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var producted: String = ""
    @State var mileage: String = ""
    @State var engHour: String = ""
    @State var diagDate: Date = Date()
    @State var osagoDate: Date = Date()
    @State var osagoLife: Date = Date()
    
    @State var isOn1: Bool = false
    @State var isOn2: Bool = false
    @State var isOn3: Bool = false
    @State var isOn4: Bool = false
    @State var isOn5: Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                Text("Транспортное средство")
                Text("Обязательное поле")
                TextField("Ник транспортного средства", text: $nick)
                Group {
                    Text("Дополнительные поля")
                    TextField("Год выпуска", text: $producted)
                    TextField("Текущий пробег", text: $mileage)
                    TextField("Моточасы", text: $engHour)
                    HStack {
                        Text("Дата получения действующей\nдиагностической карты")
                            .multilineTextAlignment(.center)
                        Spacer()
                        Toggle("", isOn: $isOn4)
                            .labelsHidden()
                    }
                    DatePicker("", selection: $diagDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    HStack {
                        Text("Дата оформления действующего\nполиса ОСАГО")
                            .multilineTextAlignment(.center)
                        Spacer()
                        Toggle("", isOn: $isOn5)
                            .labelsHidden()
                    }
                    DatePicker("", selection: $osagoDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                Button {
                    addTranspAsync()
                } label: {
                    Text("Продолжить")
                }
                .alert(isPresented: $showAlert, content: {
                    if alertMessage == "Добавить уведомления?" {
                        return Alert(title: Text("Уведомления"),
                                     message: Text(alertMessage),
                                     primaryButton: .default(Text("Позже")) {
                                        switcher = .home
                                     },
                                     secondaryButton: .default(Text("Добавить")) {
                                        showTranspAddNot = true
                                     }
                        )
                    } else {
                        return Alert(title: Text("Ошибка"), message: Text(alertMessage))
                    }
                })
                .fullScreenCover(isPresented: $showTranspAddNot, onDismiss: changeSwitcher, content: {
                    NavigationView {
                        AddTranspNotView(tid: tid, nick: nick, showTranspAddNot: $showTranspAddNot)
                    }
                })
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
    }
    
    func changeSwitcher() {
        switcher = .home
    }
    
    func addTranspAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var diagDateFormatted = ""
            var osagoDateFormatted = ""
            if isOn4 {
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY-MM-dd"
                diagDateFormatted = formatter.string(from: diagDate)
            }
            if isOn5 {
                let formatter = DateFormatter()
                formatter.dateFormat = "YYYY-MM-dd"
                osagoDateFormatted = formatter.string(from: osagoDate)
            }
            addTransp(email: globalObj.email, nick: nick, producted: producted, mileage: mileage, engHour: engHour, diagDate: diagDateFormatted, osagoDate: osagoDateFormatted)
            if alertMessage == "" {
                if isOn4 {
                    addNotification(tid: String(tid), dataType: "D", date: diagDate, value1: "", value2: "", notification: "Истекает срок действия диагностической карты")
                }
                if isOn5 {
                    addNotification(tid: String(tid), dataType: "D", date: osagoDate, value1: "", value2: "", notification: "Истекает срок действия полиса ОСАГО")
                }
            }
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    alertMessage = "Добавить уведомления?"
                    showAlert = true
                }
            }
        }
    }
    
    func addNotification(tid: String, dataType: String, date: Date, value1: String, value2: String, notification: String) {
        var dateComponent = DateComponents()
        dateComponent.day = 335
        let dateExp = Calendar.current.date(byAdding: dateComponent, to: date)
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateExp ?? Date())
        
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_notification&tid=" + tid + "&type=" + dataType + "&date=" + dateString + "&notification=" + notification
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
                    print("AddTransp.addTransp(): \(info)")
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "У вас уже есть транспортное средство с таким ником, выберите другой"
                            showAlert = true
                        } else {
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
