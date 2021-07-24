//
//  AccountEditView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 16.07.2021.
//

import SwiftUI

struct AccountEditView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var nick: String
    @Binding var showAccountEdit: Bool
    
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                TextField("Имя", text: $nick)
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .navigationBarTitle("Детали", displayMode: .inline)
        .navigationBarItems(leading:
                                Button(action: {
                                    showAccountEdit = false
                                }, label: {
                                    Text("Отменить")
                                }),
                            trailing:
                                Button(action: {
                                    updateUserInfoAsync()
                                }, label: {
                                    Text("Готово")
                                })
                            )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
    }
    
    func updateUserInfoAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            updateUserInfo(email: globalObj.email, nick: nick)
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    showAccountEdit = false
                }
            }
        }
    }
    
    func updateUserInfo(email: String, nick: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=update_user_info&email=" + email + "&nick=" + nick
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["update_user_info"] as! [String : Any]
                    print("AccountEditView.updateUserInfo(): \(info)")
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
