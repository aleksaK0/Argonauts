//
//  RowService.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 28.07.2021.
//

import SwiftUI

struct RowService: View {
    @State var service: Service
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(service.serType)
                .padding([.bottom], 5)
            HStack {
                Text("Дата:")
                    .fontWeight(.semibold)
                Text(reverseDateTime(date: service.date))
            }
            if let mileage = service.mileage {
                HStack {
                    Text("Пробег:")
                        .fontWeight(.semibold)
                    Text(String(describing: mileage))
                }
            }
            if let matCost = service.matCost {
                HStack {
                    Text("Стоимость деталей:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f", matCost).replacingOccurrences(of: ".", with: ","))
                }
            }
            if let wrkCost = service.wrkCost {
                HStack {
                    Text("Стоимость работ:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f", wrkCost).replacingOccurrences(of: ".", with: ","))
                }
            }
        }
    }
}
