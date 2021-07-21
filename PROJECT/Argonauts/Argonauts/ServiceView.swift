//
//  ServiceView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 14.07.2021.
//

import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    
    @State var showServiceDetail: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: ServiceDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showServiceDetail, label: { EmptyView() })
                List(globalObj.transports) { transport in
                    HStack {
                        Text(transport.nick)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tid = transport.tid
                        nick = transport.nick
                        showServiceDetail = true
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
