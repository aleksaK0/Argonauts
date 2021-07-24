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
        VStack(spacing: 20) {
            NavigationLink(destination: EngHourView().environmentObject(globalObj), isActive: $showEngHourView, label: { EmptyView() })
            NavigationLink(destination: MileageView().environmentObject(globalObj), isActive: $showMileageView, label: { EmptyView() })
            NavigationLink(destination: NotificationView().environmentObject(globalObj), isActive: $showNotificationView, label: { EmptyView() })
            NavigationLink(destination: StatisticsView().environmentObject(globalObj), isActive: $showStatisticsView, label: { EmptyView() })
            Button(action: {
                showEngHourView = true
            }, label: {
                Text("EngHourView")
            })
            Button(action: {
                showMileageView = true
            }, label: {
                Text("MileageView")
            })
            Button(action: {
                showNotificationView = true
            }, label: {
                Text("NotificationView")
            })
            Button(action: {
                showStatisticsView = true
            }, label: {
                Text("StatisticsView")
            })
        }
    }
}
