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
    
    var body: some View {
        VStack {
            Spacer()
            Text("Введите пин")
            Spacer()
            HStack(spacing: 15) {
                ForEach(0..<5, id: \.self) { index in
                    PinView(index: index, pin: $pin)
                }
            }
            Spacer()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                ForEach(1...9, id: \.self) { value in
                    PinButton(value: "\(value)", pin: $pin, switcher: $switcher)
                        .environmentObject(globalObj)
                }
                PinButton(value: "", pin: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
                PinButton(value: "0", pin: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
                PinButton(value: "delete.left", pin: $pin, switcher: $switcher)
                    .environmentObject(globalObj)
            }
            Spacer()
        }
    }
}
