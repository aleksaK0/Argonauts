//
//  AddTranspNotView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 21.07.2021.
//

import SwiftUI

struct AddTranspNotView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
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
                            Text(el)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            type = el
                            isExpanded = false
                        }
                        Divider()
                    }
                }
                TextField("Уведомление", text: $notification)
                switch type {
                case "Дата":
                    DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                case "Топливо":
                    TextField(type, text: $value1)
                default:
                    TextField(type, text: $value1)
                    Text("Ниже можно ввести показание \"\(type)\", при достижении которого будет отправлено уведомление, о приближении")
                        .foregroundColor(.gray)
                    TextField(type, text: $value2)
                }
                Button(action: {
                    addNotificationAsync()
                }, label: {
                    Text("Добавить")
                })
                List {
                    ForEach(notifications, id: \.nid) { notification in
                        Text(String(describing: notification.nid))
                    }
                    .onDelete(perform: deleteNotificationAsync)
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .navigationBarTitle(nick, displayMode: .inline)
        .navigationBarItems(leading:
                                Button(action: {
                                    showTranspAddNot = false
                                }, label: {
                                    Text("Отменить")
                                }),
                            trailing:
                                Button(action: {
                                    showTranspAddNot = false
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
    
    func getNotificationAsync() {
        notifications = []
        isLoading = true
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
            addNotification(tid: String(tid), dataType: type, mode: "0", date: date, value1: value1, value2: value2, notification: notification)
            DispatchQueue.main.async {
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
                isLoading = false
                if alertMessage == "" {
                    notifications.remove(at: index)
                }
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
        var value2 = value2
        
        switch dataType {
        case "Дата":
            type = "T"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru")
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            dateString = formatter.string(from: date)
        case "Пробег":
            type = "M"
        case "Топливо":
            type = "F"
            value2 = String(describing: (Int(value1)! - Int(value1)! / 10))
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
