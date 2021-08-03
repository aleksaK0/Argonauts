//
//  RepeatPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 24.06.2021.
//

import SwiftUI

struct RepeatPinView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var pinRepeat: String = ""
    @State var text: String = "Введите пин повторно"
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false    
    @State var isExists: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        switcher = .setPin
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.title3.weight(.semibold))
                    }
                    Spacer()
                }
                Text(text)
                Text(pinRepeat)
                    .onChange(of: pinRepeat) { pinRepeat in
                        if pinRepeat.count == 5 {
                            if self.pinRepeat == globalObj.pin {
                                isEmailExistsAsync()
                            } else {
                                text = "Попробуйте еще раз"
                            }
                        }
                    }
                ForEach(buttonsNoBio, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { item in
                            Button(action: {
                                switch item.rawValue {
                                case "dop":
                                    print("dop")
                                case "del":
                                    if pinRepeat != "" {
                                        pinRepeat.removeLast()
                                    }
                                default:
                                    pinRepeat.append(item.rawValue)
                                }
                            }, label: {
                                if item.rawValue == "del" {
                                    Image(systemName: "delete.left")
                                } else if item.rawValue == "dop" {
                                    Text("")
                                } else {
                                    Text(item.rawValue)
                                }
                            })
                        }
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
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        })
    }
    
    func isEmailExistsAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            isEmailExists(email: globalObj.email)
            if isExists {
                let textToWrite = globalObj.email + "\n" + globalObj.pin
                writeToDocDir(filename: "pinInfo", text: textToWrite)
            }
            DispatchQueue.main.async {
                if isExists {
                    switcher = .home
                } else if isExists == false && alertMessage == "" {
                    switcher = .createAccount
                }
                isLoading = false
            }
        }
    }
    
    func isEmailExists(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=is_email_exists&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["user"] as! [String : Any]
                    print("RepeatPinView.isEmailExists(): \(info)")
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else if info["no"] != nil {
                        alertMessage = ""
                        isExists = false
                    } else {
                        alertMessage = ""
                        isExists = true
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
