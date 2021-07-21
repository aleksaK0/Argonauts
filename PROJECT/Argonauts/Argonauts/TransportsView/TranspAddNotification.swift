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
    
    @State var isExpanded: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    @State var alertMessage: String = ""
    @State var type: String = "Дата"
    @State var notification: String = ""
    @State var date: Date = Date()
    @State var value1: String = ""
    @State var value2: String = ""
    
    @State var types: [String] = ["Дата", "Пробег", "Топливо", "Моточасы"]
    
    @State var notifications: [Notification] = []
    
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
                    .onDelete(perform: deleteMaterialAsync)
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
        .navigationBarTitle(nick, displayMode: .inline)
        .navigationBarItems(leading:
                                Button(action: {
                                    showTranspAddNot = false
                                    isPresented = false
                                }, label: {
                                    Text("Отменить")
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
            loadDataAsync()
        }
    }
    
    func loadDataAsync() {
        notifications = []
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let notifications = getNotification(tid: String(tid))
            DispatchQueue.main.async {
                self.notifications = notifications
                isLoading = false
            }
        }
    }
    
    func addNotificationAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addNotification(tid: String(tid), dataType: type, date: date, value1: value1, value2: value2, notification: notification)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func deleteMaterialAsync(at offsets: IndexSet) {
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
    
    func getNotification(tid: String) -> [Notification] {
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
                        var notifications: [Notification] = []
                        for el in info {
                            let notification = Notification(nid: el["nid"] as! Int, tid: el["tid"] as! Int, type: el["type"] as! String, date: el["date"] as? String, value1: el["value1"] as? Int, value2: el["value2"] as? Int, notification: el["notification"] as! String)
                            notifications.append(notification)
                        }
                        return notifications
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
        return []
    }
    
    func addNotification(tid: String, dataType: String, date: Date, value1: String, value2: String, notification: String) {
        var type: String = ""
        var dateString = ""
        
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
        case "Моточасы":
            type = "H"
        default:
            type = ""
        }
        
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_notification&tid=" + tid + "&type=" + type + "&date=" + dateString + "&value1=" + value1 + "&value2=" + value2 + "&notification=" + notification
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
                        notifications.append(Notification(nid: info["nid"] as! Int, tid: info["tid"] as! Int, type: info["type"] as! String, date: info["date"] as? String, value1: info["value1"] as? Int, value2: info["value2"] as? Int, notification: info["notification"] as! String))
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
