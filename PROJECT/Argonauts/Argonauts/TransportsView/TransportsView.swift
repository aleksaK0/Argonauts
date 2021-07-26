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
    @State var transports: [Transport] = []
    
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
                            .font(.title.weight(.semibold))
//                            .foregroundColor(.yellow)
                            .foregroundColor(ColorManager.customYellow)
                    }
                    .padding(.trailing)
                }
                HStack {
                    Text("Транспорт")
                        .font(.title.weight(.bold))
                        .padding([.leading])
                    Spacer()
                }
                NavigationLink(destination: TranspDetailView(tid: tid, nick: nick).environmentObject(globalObj), isActive: $showTranspDetail, label: { EmptyView() })
                List(transports) { transport in
                    Button(action: {
                        tid = transport.tid
                        nick = transport.nick
                        showTranspDetail = true
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
        .fullScreenCover(isPresented: $showTranspAdd, onDismiss: getTidTnickAsync) {
            NavigationView {
                TranspAddView(isPresented: $showTranspAdd).environmentObject(globalObj)
            }
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

