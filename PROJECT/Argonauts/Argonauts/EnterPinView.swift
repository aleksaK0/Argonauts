//
//  EnterPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 30.06.2021.
//

import SwiftUI
import LocalAuthentication

struct EnterPinView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var pin: String = ""
    @State var text: String = "Введите пин"
    @State var pinInfo: [String] = []
    
    @State var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text(text)
                    .font(.title.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(pin)
                    .onChange(of: pin) { pin in
                        if pin.count == 5 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if pin == pinInfo[1] {
                                    switcher = .home
                                } else {
                                    text = "Неверный пин"
                                }
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
        .onAppear {
            readPinInfoAsync()
            authenticate()
        }
    }
    
    func setPin(value: numPadButton) {
        if value == .del && pin.count > 0 {
            pin.removeLast()
        } else {
            pin.append(value.rawValue)
        }
    }
    
    func readPinInfoAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            readPinInfo()
            DispatchQueue.main.async {
                isLoading = false
            }
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
                        switcher = .home
                    } else {
                    }
                }
            }
        } else {
            globalObj.biometryType = "none"
        }
    }
    
    func readPinInfo() {
        let filename: String = "pinInfo.txt"
        do {
            let docDirUrl =  try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileUrl = docDirUrl.appendingPathComponent(filename)
            
            do {
                let contentFromFile = try NSString(contentsOf: fileUrl, encoding: String.Encoding.utf8.rawValue)
                pinInfo = contentFromFile.components(separatedBy: "\n")
                print("EnterPinView.readPinInfo(): \(pinInfo)")
                globalObj.email = pinInfo[0]
            } catch let error as NSError {
                print("EnterPinView.readPinInfo(): \(error)")
            }
            
        } catch let error as NSError {
            print("EnterPinView.readPinInfo(): \(error)")
        }
    }
}
