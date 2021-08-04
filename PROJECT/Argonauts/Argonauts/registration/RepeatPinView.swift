//
//  RepeatPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 24.06.2021.
//

import SwiftUI
import LocalAuthentication

struct RepeatPinView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var pinRepeat: String = "1234"
    @State var text: String = "Введите пин повторно"
    @State var alertMessage: String = ""
    
    @State var isLoading: Bool = false    
    @State var isExists: Bool = false
    @State var showAlert: Bool = false
    @State var authenticated: Bool? = nil
    
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
                .padding([.leading, .trailing, .top])
                Spacer()
                Text(text)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(pinRepeat)
                    .onChange(of: pinRepeat) { value in
                        if value.count == 5 {
                            if value == globalObj.pin {
                                isEmailExistsAsync()
                            } else {
                                text = "Пин не совпадает"
                            }
                        }
                    }
                    .font(.title2)
                    .frame(height: 45)
                    .padding()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(butNotBio, id: \.self) { value in
                        Button {
                            setPin(value: value)
                        } label: {
                            if value.rawValue == "delete.left" {
                                Image(systemName: value.rawValue)
                                    .font(.title)
                                    .foregroundColor(.reverseColor)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .circular)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: UIScreen.main.bounds.width / 4.5, height: UIScreen.main.bounds.width / 8)
                                    )
                                    .frame(width: UIScreen.main.bounds.width / 4.5, height: UIScreen.main.bounds.width / 8)
                            } else if value.rawValue != "" {
                                Text(value.rawValue)
                                    .font(.title)
                                    .foregroundColor(.reverseColor)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .circular)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: UIScreen.main.bounds.width / 4.5, height: UIScreen.main.bounds.width / 8)
                                    )
                                    .frame(width: UIScreen.main.bounds.width / 4.5, height: UIScreen.main.bounds.width / 8)
                            }
                        }
                    }
                }
                .padding()
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
    
    func setPin(value: numPadButton) {
        if value == .del && pinRepeat.count > 0 {
            pinRepeat.removeLast()
        } else {
            pinRepeat.append(value.rawValue)
        }
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
                } else if alertMessage == "" {
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
                if success {
                    print("success")
                } else {
                    print("failed")
                }
            }
        } else {
            globalObj.biometryType = "none"
            print("none")
        }
    }
}
