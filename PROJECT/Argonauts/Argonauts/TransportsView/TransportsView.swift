//
//  TransportsView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 29.06.2021.
//

import SwiftUI

struct TransportsView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var alertMessage: String = ""
    @State var tid: Int = 0
    @State var nick: String = ""
    
    
    @State var showTranspDetail: Bool = false
    @State var showTranspAdd: Bool = false
    @State var isLoading: Bool = true
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showTranspAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .padding(.trailing)
                }
                NavigationLink(destination: TranspDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showTranspDetail, label: { EmptyView() })
                List(globalObj.transports) { transport in
                    HStack {
                        Text(transport.nick)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        nick = transport.nick
                        tid = transport.tid
                        showTranspDetail = true
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
        .fullScreenCover(isPresented: $showTranspAdd) {
            NavigationView {
                TranspAddView(isPresented: $showTranspAdd).environmentObject(globalObj)
                    .onDisappear {
                        loadDataAsync()
                    }
            }
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
