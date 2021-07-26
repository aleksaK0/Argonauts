//
//  MileageAdd.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 07.07.2021.
//

import SwiftUI

struct MileageView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    @State var transports: [Transport] = []
    
    @State var showMileageDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                NavigationLink(destination: MileageDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showMileageDetail, label: { EmptyView() })
                List(transports) { transport in
                    Button(action: {
                        tid = transport.tid
                        nick = transport.nick
                        showMileageDetail = true
                    }, label: {
                        Text(transport.nick)
                    })
                }
            }
            if isLoading {
                Rectangle()
                    .fill(Color.loadingColor.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .navigationBarTitle("Пробег", displayMode: .inline)
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
