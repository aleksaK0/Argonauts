//
//  RowNotification.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 26.07.2021.
//

import SwiftUI

struct RowNotification: View {
    @State var notification: Notification
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notification.notification)
                .padding([.bottom], 5)
            HStack {
                Text("Критерий:")
                    .fontWeight(.semibold)
                Text(getType(type: notification.type))
            }
            if notification.type == "D" {
                HStack {
                    Text("Дата:")
                        .fontWeight(.semibold)
                    Text(reverseDate(date: notification.date!))
                }
            } else {
                if let value2 = notification.value2 {
                    HStack {
                        Text("Приближение:")
                            .fontWeight(.semibold)
                        Text(String(describing: value2))
                    }
                    HStack {
                        Text("Наступление:")
                            .fontWeight(.semibold)
                        Text(String(describing: notification.value1!))
                    }
                } else {
                    HStack {
                        Text("Наступление:")
                            .fontWeight(.semibold)
                        Text(String(describing: notification.value1!))
                    }
                }
            }
        }
    }
    
    func getType(type: String) -> String {
        switch type {
        case "D":
            return "Дата"
        case "H":
            return "Моточасы"
        case "M":
            return "Пробег"
        case "F":
            return "Топливо"
        default:
            return ""
        }
    }
}
