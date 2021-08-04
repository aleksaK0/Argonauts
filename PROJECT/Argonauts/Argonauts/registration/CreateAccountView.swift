//
//  CreateAccount.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 25.06.2021.
//

import SwiftUI
import LocalAuthentication

struct CreateAccountView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var nick: String = "A"
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Введите своё имя")
                    .font(.title.weight(.semibold))
                Spacer()
                TextField("Имя"
                          , text: $nick
                          , onEditingChanged: { _ in }
                          , onCommit: {
                            UIApplication.shared.endEditing()
                            addUserAsync()
                          })
                    .disableAutocorrection(true)
                    .font(.title3)
                    .padding()
                Spacer()
                Button {
                    UIApplication.shared.endEditing()
                    addUserAsync()
                } label: {
                    Text("Продолжить")
                        .font(.title3)
                }
                Spacer()
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
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
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
    
    func addUserAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if isValidNick(nick: nick) {
                addUser(email: globalObj.email, nick: nick)
                if alertMessage == "" {
                    writeToDocDir(filename: "pinInfo", text: globalObj.email + "\n" + globalObj.pin)
                }
            } else {
                alertMessage = "Введены некорректные данные"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    switcher = .addTransp
                }
                isLoading = false
            }
        }
    }
    
    func addUser(email: String, nick: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_user&email=" + email + "&nick=" + nick
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["new_user"] as! [String : Any]
                    print("CreateAccountView.addUser(): \(dop)")
                    
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
}
