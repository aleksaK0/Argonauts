//
//  NotificationView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 16.07.2021.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var transports: [Transport] = []
    
    @State var showNotificationDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: NotificationDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showNotificationDetail, label: { EmptyView() })
                List(transports) { transport in
                    Button(action: {
                        tid = transport.tid
                        nick = transport.nick
                        showNotificationDetail = true
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
        .navigationBarTitle("Уведомления", displayMode: .inline)
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
