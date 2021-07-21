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
    
    var body: some View {
        VStack {
            Spacer()
            TextField("Имя", text: $nick)
            TextField("Email", text: $globalObj.email)
            Spacer()
        }
    }
}
