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
    
    @State var nick: String = ""
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("Введите своё имя")
                TextField("Ник"
                          , text: $nick
                          , onEditingChanged: { _ in }
                          , onCommit: {
                            
                          })
                Button {
                    addUserAsync()
                } label: {
                    Text("Продолжить")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Ошибка"), message: Text(alertMessage))
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
    }
    
    func addUserAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addUser(email: globalObj.email, nick: nick)
            if alertMessage == "" {
                writeToDocDir(filename: "pinInfo", text: globalObj.email + "\n" + globalObj.pin)
            }
            DispatchQueue.main.async {
                isLoading = false
                authenticate()
                if alertMessage == "" {
                    switcher = .addTransp
                }
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
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Вы сможете осуществлять вход в приложение с помощью биометрии"
            
            switch context.biometryType {
            case .faceID:
                print("EnterPinView.authenticate(): faceID")
                globalObj.biometryType = "faceID"
            case .touchID:
                print("EnterPinView.authenticate(): touchID")
                globalObj.biometryType = "touchID"
            default:
                print("EnterPinView.authenticate(): none")
                globalObj.biometryType = "none"
            }
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        
                    } else {
                        
                    }
                }
            }
        } else {
            globalObj.biometryType = "none"
        }
    }
}
