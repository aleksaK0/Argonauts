//
//  SetPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 23.06.2021.
//

import SwiftUI

struct SetPinView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var pin: String = ""
    @State var buttons: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"]
    
    var body: some View {
        VStack {
            Spacer()
            Text("Введите пин")
            Spacer()
            HStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { index in
                    PasswordView(index: index, password: $pin)
                }
            }
            Spacer()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                ForEach(1...9, id: \.self) { value in
                    PasswordButton(value: "\(value)", password: $pin, switcher: $switcher)
                        .environmentObject(globalObj)
                }
                PasswordButton(value: "", password: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
                PasswordButton(value: "0", password: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
                PasswordButton(value: "delete.left", password: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
            }
            Spacer()
        }
    }
}

struct PasswordButton: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    var value: String
    @Binding var password: String
    @Binding var switcher: Views
    
    var body: some View {
        Button(action: {
            setPin()
        }, label: {
            if value == "delete.left" {
                Image(systemName: value)
                    .font(.title)
                    .foregroundColor(.reverseColor)
                    .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.height / 10)
//                    .background(Color.red)
            } else {
                Text(value)
                    .font(.title)
                    .foregroundColor(.reverseColor)
                    .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.height / 10)
//                    .background(Color.red)
            }
        })
    }
    
    func setPin() {
        if value.count > 1 {
            if password.count != 0 {
                password.removeLast()
            }
        } else {
            if password.count != 5 {
                password.append(value)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if password.count == 5 {
                        globalObj.pin = password
                        switcher = .repeatPin
                    }
                }
            }
        }
    }
}

struct PasswordView: View {
    var index: Int
    @Binding var password: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 30, height: 30)
            if password.count > index {
                Circle()
                    .frame(width: 30, height: 30)
            }
        }
    }
}
