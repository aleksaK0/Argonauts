//
//  EntryView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 21.06.2021.
//

import SwiftUI

struct EntryView: View {
    @StateObject var globalObj: GlobalObj = GlobalObj()
    @State var switcher: Views
    
    var body: some View {
        if switcher == .enterEmail {
            EnterEmailView(switcher: $switcher).environmentObject(globalObj) // ввод email'a
        } else if switcher == .enterPassCode {
            EnterPassCodeView(switcher: $switcher).environmentObject(globalObj) // ввода кода из письма
        } else if switcher == .setPin {
            SetPinView(switcher: $switcher).environmentObject(globalObj) // ввода пина
        } else if switcher == .repeatPin {
            RepeatPinView(switcher: $switcher).environmentObject(globalObj) // подтверждение пина
        } else if switcher == .createAccount {
            CreateAccountView(switcher: $switcher).environmentObject(globalObj) // создание аккаунта
        } else if switcher == .addTransp {
            AddTranspView(switcher: $switcher).environmentObject(globalObj) // добавление автомобиля
        } else if switcher == .home {
            HomeView(switcher: $switcher).environmentObject(globalObj) // домашний экран
        } else if switcher == .enterPin {
            EnterPinView(switcher: $switcher).environmentObject(globalObj) // ввод пин-кода
        }
    }
}
