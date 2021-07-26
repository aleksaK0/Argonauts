//
//  HubView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 14.07.2021.
//

import SwiftUI

struct HubView: View {
    @EnvironmentObject var globalObj: GlobalObj
    
    @State var showEngHourView: Bool = false
    @State var showMileageView: Bool = false
    @State var showNotificationView: Bool = false
    @State var showStatisticsView: Bool = false
    
    var body: some View {
        VStack {
            Group {
                NavigationLink(destination: EngHourView().environmentObject(globalObj), isActive: $showEngHourView, label: { EmptyView() })
                NavigationLink(destination: MileageView().environmentObject(globalObj), isActive: $showMileageView, label: { EmptyView() })
                NavigationLink(destination: NotificationView().environmentObject(globalObj), isActive: $showNotificationView, label: { EmptyView() })
                NavigationLink(destination: StatisticsView().environmentObject(globalObj), isActive: $showStatisticsView, label: { EmptyView() })
            }
            Spacer()
            Button(action: {
                showEngHourView = true
            }, label: {
                Text("Моточасы")
//                    .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.height / 8, alignment: .center)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(UIScreen.main.bounds.width * 0.05)
            })
            Spacer()
            Button(action: {
                showMileageView = true
            }, label: {
                Text("Пробег")
//                    .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.height / 8, alignment: .center)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(UIScreen.main.bounds.width * 0.05)
            })
            Spacer()
            Button(action: {
                showNotificationView = true
            }, label: {
                Text("Уведомления")
//                    .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.height / 8, alignment: .center)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(UIScreen.main.bounds.width * 0.05)
            })
            Spacer()
            Button(action: {
                showStatisticsView = true
            }, label: {
                Text("Статистика")
//                    .frame(width: UIScreen.main.bounds.width - 50, height: UIScreen.main.bounds.height / 8, alignment: .center)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(UIScreen.main.bounds.width * 0.05)
            })
            Spacer()
        }
    }
}
