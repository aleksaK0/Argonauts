//
//  PinView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 02.08.2021.
//

import SwiftUI

struct PinView: View {
    var index: Int
    @Binding var pin: String
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 25, height: 25)
            if pin.count > index {
                Circle()
                    .frame(width: 25, height: 25)
            }
        }
    }
}
