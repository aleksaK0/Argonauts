//
//  RowNotification.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 26.07.2021.
//

import SwiftUI

struct RowNotification: View {
    @State var notification: String
    @State var type: String
    @State var date: String?
    @State var value1: Int?
    @State var value2: Int?
    
//    @State var notification: String = "Замена масла"
//    @State var type: String = "Дата"
//    @State var date: Date = Date()
//    @State var value1: String = ""
//    @State var value2: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(notification)
                .fontWeight(.semibold)
            HStack {
                Text("Критерий:")
                    .fontWeight(.semibold)
                Text(getType(type: type))
            }
            if type == "D" {
                HStack {
                    Text("Дата:")
                        .fontWeight(.semibold)
                    Text(reverseDate(date: String(describing: date!)))
                }
            } else {
                if let value2 = value2 {
                    HStack {
                        Text("Приближение:")
                            .fontWeight(.semibold)
                        Text(String(describing: value2))
                    }
                    HStack {
                        Text("Наступление:")
                            .fontWeight(.semibold)
                        Text(String(describing: value1!))
                    }
                } else {
                    HStack {
                        Text("Наступление:")
                            .fontWeight(.semibold)
                        Text(String(describing: value1!))
                    }
                }
            }
        }
    }
    
    func reverseDate(date: String) -> String {
        let comp = date.components(separatedBy: "-")
        let revDate = comp[2] + "." + comp[1] + "." + comp[0]
        return revDate
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

//struct RowNotification_Previews: PreviewProvider {
//    static var previews: some View {
//        RowNotification()
//    }
//}
