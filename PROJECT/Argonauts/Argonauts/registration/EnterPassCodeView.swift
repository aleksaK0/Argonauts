//
//  EnterPassCode.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 22.06.2021.
//

import SwiftUI

struct EnterPassCodeView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @Binding var switcher: Views
    
    @State var userPassCode: String = "1234"
    @State var text: String = "Ввeдите код"
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    switcher = .enterEmail
                } label: {
                    Image(systemName: "chevron.backward")
                        .font(.title3.weight(.semibold))
                }
                Spacer()
            }
            .padding([.leading, .trailing, .top])
            Spacer()
            Text(text)
            Spacer()
            TextField("Код", text: $userPassCode)
                .keyboardType(.numberPad)
                .onChange(of: userPassCode, perform: { value in
                    if userPassCode.count > 4 {
                        userPassCode.removeLast()
                    }
                })
                .padding()
            Spacer()
            Button {
                if userPassCode == globalObj.sentPassCode {
                    switcher = .setPin
                } else {
                    text = "Неверный код, попробуйте снова"
                }
            } label: {
                Text("Продолжить")
            }
            .disabled(userPassCode.isEmpty)
            Spacer()
        }
    }
}
