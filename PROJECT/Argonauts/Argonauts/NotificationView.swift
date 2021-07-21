//
//  NotificationView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 16.07.2021.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var alertMessage: String = ""
    
    @State var showNotificationDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: NotificationDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showNotificationDetail, label: { EmptyView() })
                List(globalObj.transports) { transport in
                    HStack {
                        Text(transport.nick)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tid = transport.tid
                        nick = transport.nick
                        showNotificationDetail = true
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
        .navigationBarTitle("Уведомления", displayMode: .inline)
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

//struct NotificationView_Previews: PreviewProvider {
//    static var previews: some View {
//        NotificationView().environmentObject(GlobalObj())
//    }
//}
