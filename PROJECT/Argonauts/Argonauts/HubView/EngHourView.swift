//
//  EngHourView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 09.07.2021.
//

import SwiftUI

struct EngHourView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var transports: [Transport] = []
    
    @State var showEngHourDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: EngHourDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showEngHourDetail, label: { EmptyView() })
                List(transports) { transport in
                    Button(action: {
                        tid = transport.tid
                        nick = transport.nick
                        showEngHourDetail = true
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
        .navigationBarTitle("Моточасы", displayMode: .inline)
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
