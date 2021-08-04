//
//  SetPinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 23.06.2021.
//

import SwiftUI

struct SetPinView: View {
    @Binding var switcher: Views
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var pin: String = "1234"
    @State var text: String = "Введите пин"
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    switcher = .enterPassCode
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
            Text(pin)
                .onChange(of: pin) { pin in
                    if pin.count == 5 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            globalObj.pin = pin
                            switcher = .repeatPin
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
    }
    
    func setPin(value: numPadButton) {
        if value == .del && pin.count > 0 {
            pin.removeLast()
        } else {
            pin.append(value.rawValue)
        }
    }
}
