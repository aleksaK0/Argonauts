//
//  EnterEmailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 04.07.2021.
//

import SwiftUI

struct EnterEmailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var email: String = ""
    @State var alertMessage: String = ""
    
    @State var showAlert: Bool = false
    @State var isEditing: Bool = false
    @State var isLoading: Bool = false
    @State var isValid: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Регистрация")
                Spacer()
                TextField("Email"
                          , text: $email
                          , onEditingChanged: { _ in  }
                          , onCommit: {
                            isValid = isValidEmailAddress(email: email)
                            #warning("delete line below in fp")
                            isValid = true
                            if isValid {
                                connectDeviceAsync()
                            } else {
                                alertMessage = "Введён некорректный email, попробуйте ещё раз"
                                showAlert = true
                            }
                            connectDeviceAsync()
                          })
                    .keyboardType(.emailAddress)
                    .padding()
                Spacer()
                Button {
                    UIApplication.shared.endEditing()
                    isValid = isValidEmailAddress(email: email)
                    #warning("delete line below in fp")
                    isValid = true
                    if isValid {
                        connectDeviceAsync()
                    } else {
                        alertMessage = "Введён некорректный email, попробуйте ещё раз"
                        showAlert = true
                    }
                } label: {
                    Text("Зарегестрироваться")
                }
                .disabled(email.isEmpty)
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
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        })
    }
    
    func connectDeviceAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            //            globalObj.sentPassCode = generatePassCode()
            #warning("delete line below in fp")
            globalObj.sentPassCode = "1234"
            //            connectDevice(email: email, code: globalObj.sentPassCode)
            DispatchQueue.main.async {
                if alertMessage == "" {
                    globalObj.email = email
                    switcher = .enterPassCode
                }
                isLoading = false
            }
        }
    }
    
    func connectDevice(email: String, code: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=connect_device&email=" + email + "&code=" + code
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["message"] as! [String : Any]
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
}
