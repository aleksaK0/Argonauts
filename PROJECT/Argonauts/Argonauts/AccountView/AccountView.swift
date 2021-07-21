//
//  AccountView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 29.06.2021.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    @State var showAccountEdit: Bool = false
    @State var showAccountEmail: Bool = false
    @State var fileRemoved: Bool = false
    
    @State var alertMessage: String = ""
    @State var nick: String = "Александра"
    @State var selection: String? = nil
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: AccountEmailView(email: globalObj.email, switcher: $switcher), tag: "Почта", selection: $selection, label: { EmptyView() })
                Button(action: {
                    showAccountEdit = true
                }, label: {
                    Text("Изменить")
                })
                Text(nick)
                Text(globalObj.email)
                List {
                    HStack {
                        Button(action: {
                            selection = "Почта"
                        }, label: {
                            Text("Почта")
                        })
                    }
                }
                Button(action: {
                    alertMessage = "Вы уверены, что хотите выйти из аккаунта?"
                    showAlert = true
                }, label: {
                    Text("Выйти")
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
        .alert(isPresented: $showAlert) {
            if alertMessage == "Вы уверены, что хотите выйти из аккаунта?" {
                return Alert(
                    title: Text("Выход"),
                    message: Text(alertMessage),
                    primaryButton: .destructive(Text("Выйти")) {
                        removePinFileAsync()
//                        exit = true
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(title: Text("Ошибка"), message: Text(alertMessage))
            }
        }
        //        .fullScreenCover(isPresented: $showAccountEdit, content: {
        //            AccountEditView(nick: nick).environmentObject(globalObj)
        //        })
        .onAppear {
            loadDataAsync()
        }
    }
    
    func removePinFileAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            removePinFile()
            DispatchQueue.main.async {
                isLoading = false
                if fileRemoved {
                    switcher = .enterEmail
                } else {
                    alertMessage = "Ошибка"
                    showAlert = true
                }
            }
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
    
    func loadDataAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            getUserInfo(email: globalObj.email)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func getUserInfo(email: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_user_info&email=" + email
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_user_info"] as! [[String : Any]]
                    print("AccountView.getUserInfo(): \(info)")
                    
                    if info.isEmpty {
//                        exit = true
                    } else if info[0]["server_error"] != nil {
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
