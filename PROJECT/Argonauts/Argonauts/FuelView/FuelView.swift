//
//  RefuelView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 13.07.2021.
//

import SwiftUI

struct FuelView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var transports: [Transport] = []
    
    @State var showFuelDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: FuelDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showFuelDetail, label: { EmptyView() })
                List(transports) { transport in
                    Button(action: {
                        tid = transport.tid
                        nick = transport.nick
                        showFuelDetail = true
                    }, label: {
                        Text(transport.nick)
                    })
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getTidTnickAsync()
        }
    }
    
    func getTidTnickAsync() {
        isLoading = true
        transports = []
        DispatchQueue.global(qos: .userInitiated).async {
            getTidTnick(email: globalObj.email, alertMessage: &alertMessage, showAlert: &showAlert, transports: &transports)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}
