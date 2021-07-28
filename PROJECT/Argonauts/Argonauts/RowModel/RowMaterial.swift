//
//  RowMaterial.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 15.07.2021.
//

import SwiftUI

struct RowMaterial: View {
    @State var material: Material
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(material.matInfo)
                .padding([.bottom], 5)
            HStack {
                Text("Тип работы:")
                    .fontWeight(.semibold)
                Text(material.wrkType)
            }
            if let matCost = material.matCost {
                HStack {
                    Text("Стоимость детали:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f", matCost))
                }
            }
            if let wrkCost = material.wrkCost {
                HStack {
                    Text("Стоимость детали:")
                        .fontWeight(.semibold)
                    Text(String(format: "%.2f", wrkCost))
                }
            }
        }
    }
}
