//
//  EngHourView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 09.07.2021.
//

import SwiftUI

struct EngHourView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var alertMessage: String = ""
    
    @State var showEngHourDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: EngHourDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showEngHourDetail, label: { EmptyView() })
                List(globalObj.transports) { transport in
                    HStack {
                        Text(transport.nick)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tid = transport.tid
                        nick = transport.nick
                        showEngHourDetail = true
                    }
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .pink))
            }
        }
        .navigationBarTitle("Моточасы", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        globalObj.transports = []
        DispatchQueue.global(qos: .userInitiated).async {
            let transports = getTidTnick(email: globalObj.email, alertMessage: &alertMessage, showAlert: &showAlert)
            DispatchQueue.main.async {
                globalObj.transports = transports
                isLoading = false
            }
        }
    }
}
