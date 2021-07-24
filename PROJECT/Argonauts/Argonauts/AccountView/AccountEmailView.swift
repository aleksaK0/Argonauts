//
//  EmailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 20.07.2021.
//

import SwiftUI

struct AccountEmailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var email: String
    @Binding var switcher: Views
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    @State var showFields: Bool = false
    @State var codeSent: Bool = false
    @State var fileRemoved: Bool = false
    
    @State var alertMessage: String = ""
    @State var send: Int = -1
    @State var selecEmail: String = ""
    @State var newEmail: String = ""
    @State var code: String = ""
    @State var sentCode: String = ""
    @State var emails: [Email] = []
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    TextField("Почта", text: $newEmail)
                    if codeSent {
                        TextField("Код", text: $code)
                        Button(action: {
//                            if code == sentCode {
//                                addEmailAsync()
//                            }
                            if code == "1234" {
                                addEmailAsync()
                            }
                        }, label: {
                            Text("Подтвердить")
                        })
                    } else {
                        Button(action: {
//                            connectDeviceAsync()
                            codeSent = true
                        }, label: {
                            Text("Продолжить")
                        })
                    }
                }
                List {
                    ForEach(emails, id: \.eid) { email in
                        HStack {
                            Text(String(describing: email.email))
                            Text(String(describing: email.send))
                            Spacer()
                            Button(action: {
                                selecEmail = email.email
                                if email.send == 0 {
                                    send = 1
                                } else {
                                    send = 0
                                }
                                changeEmailSendAsync()
                            }, label: {
                                Image(systemName: email.send == 0 ? "envelope" : "envelope.fill")
                            })
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .onDelete(perform: deleteEmailAsync)
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
        .navigationBarTitle("Почта", displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    showFields.toggle()
                                }, label: {
                                    if showFields {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getEmailAsync()
        }
    }
    
    func removePinFile() {
        let filename = "pinInfo"
        let ext = "txt"
        let DocDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = DocDirURL.appendingPathComponent(filename).appendingPathExtension(ext)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            fileRemoved = true
        } catch let error as NSError {
            print(error)
            fileRemoved = false
        }
    }
    
    func getEmailAsync() {
        emails = []
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            getEmail(email: email)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func addEmailAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addEmail(email: email, newEmail: newEmail)
            DispatchQueue.main.async {
                isLoading = false
                codeSent = false
            }
        }
    }
    
    func deleteEmailAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            email = emails[index].email
            deleteEmail(email: email)
            if alertMessage == "" && email == globalObj.email {
                removePinFile()
            }
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    if fileRemoved {
                        emails.remove(at: index)
                        switcher = .enterEmail
                    } else {
                        emails.remove(at: index)
                    }
                }
            }
        }
    }
    
    func connectDeviceAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            sentCode = generatePassCode()
            connectDevice(email: newEmail, code: sentCode)
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    codeSent = true
                }
            }
        }
    }
    
    func changeEmailSendAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            changeEmailSend(email: selecEmail, send: String(send))
            emails = []
            getEmail(email: globalObj.email)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func changeEmailSend(email: String, send: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=change_email_send&email=" + email + "&send=" + send
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["change_email_send"] as! [String : Any]
                    print("AccountEmailView.update(): \(info)")
                    
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
    
    func getEmail(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_email&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_email"] as! [[String : Any]]
                    print("AccountEmailView.getUserEmail(): \(info)")
                    
                    if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            emails.append(Email(eid: el["eid"] as! Int, email: el["email"] as! String, send: el["send"] as! Int))
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
    
    func addEmail(email: String, newEmail: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_email&email=" + email + "&new_email=" + newEmail
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_email"] as! [String : Any]
                    print("AccountEmailView.addEmail(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Эта почта уже есть в базе"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else {
                        alertMessage = ""
                        emails.append(Email(eid: info["eid"] as! Int, email: info["new_email"] as! String, send: info["send"] as! Int))
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
    
    func deleteEmail(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_email&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_email"] as! [String : Any]
                    print("AccountEmailView.deleteEmail(): \(info)")
                    
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
    
    func connectDevice(email: String, code: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=connect_device&email=" + email + "&code=" + code
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["connect_device"] as! [String : Any]
                    print("EnterEmailView.connectDevice(): \(dop)")
                    
                    if dop["server_error"] != nil {
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
    
    func generatePassCode() -> String {
        let passCode = String(Int.random(in: 100000...999999))
        return passCode
    }
}
