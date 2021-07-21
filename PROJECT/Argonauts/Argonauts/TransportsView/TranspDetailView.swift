//
//  TranspDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 30.06.2021.
//

import SwiftUI

struct TranspDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var alertMessage: String = ""
    @State var transpInfo: [String : Any] = [:]
    @State var keys: [String] = ["Ник", "Год выпуска", "Пробег", "Моточасы", "Дата диаг. карты", "Дата ОСАГО", "Сум. расход топлива", "Дата начала"]
    @State var values: [String] = ["", "", "", "", "", "", "", ""]
    
    @State var isLoading: Bool = true
    @State var showTranspEditDetail: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    ForEach(Array(zip(keys, values)), id: \.0) { item in
                        HStack {
                            Text("\(item.0)")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(item.1)
                        }
                    }
                    Button(action: {
                        discardFuelAsync()
                    }, label: {
                        Text("Сбросить топливо")
                    })
                    Button(action: {
                        alertMessage = "Вы уверены, что хотите удалить данное транспортное средство?"
                        showAlert = true
                    }, label: {
                        Text("Удалить")
                    })
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
        .navigationBarTitle(values[0], displayMode: .inline)
        .navigationBarItems(
            trailing:
                Button(action: {
                    showTranspEditDetail = true
                }, label: {
                    Text("Изменить")
                })
        )
        .alert(isPresented: $showAlert) {
            if alertMessage == "Вы уверены, что хотите удалить данное транспортное средство?" {
                return Alert(title: Text("Внимание"),
                             message: Text(alertMessage),
                             primaryButton: .cancel(),
                             secondaryButton: .destructive(Text("Удалить")) {
                                deleteTranspAsync()
                             })
            } else {
                return Alert(title: Text("Ошибка"), message: Text(alertMessage))
            }
        }
        .fullScreenCover(isPresented: $showTranspEditDetail, onDismiss: loadDataAsync) {
            NavigationView {
                TranspDetailEditView(isPresented: $showTranspEditDetail, tid: String(tid), nick: values[0], producted: values[1], diagDate: convertStringToDate(string: values[4]), osagoDate: convertStringToDate(string: values[5]), diagDateStr: values[4], osagoDateStr: values[5], diagDateChanged: values[4] != "", osagoDateChanged: values[5] != "")
            }
        }
        .onAppear {
            loadDataAsync()
        }
    }
    
    func convertStringToDate(string: String) -> Date {
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy-MM-dd"
        let date = formmater.date(from: string)
        return date ?? Date()
    }
    
    func loadDataAsync() {
        values = ["", "", "", "", "", "", "", ""]
        DispatchQueue.global(qos: .userInitiated).async {
            getTransportInfo(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func deleteTranspAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            deleteTransp(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
                if alertMessage == "" {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func discardFuelAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            discardFuel(tid: String(tid))
            getTransportInfo(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func discardFuel(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=discard_fuel&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["discard_fuel"] as! [String : Any]
                    print("TranspDetailView.discardFuel(): \(info)")
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
    
    func getTransportInfo(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_transport_info&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let dop = json["transport_info"] as! [[String : Any]]
                    let info = dop[0]
                    print("TranspDetailView.getTransportInfo(): \(info)")
                    
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        values[0] = info["nick"] as! String
                        if info["producted"] is NSNull == false {
                            let producted = info["producted"] as! Int
                            values[1] = String(producted)
                        }
                        if info["mileage"] is NSNull == false {
                            let mileage = info["mileage"] as! Int
                            values[2] = String(mileage)
                        }
                        if info["eng_hour"] is NSNull == false {
                            let engHour = info["eng_hour"] as! Int
                            values[3] = String(engHour)
                        }
                        if info["diag_date"] is NSNull == false {
                            let diagDate = info["diag_date"] as! String
                            values[4] = diagDate
                        }
                        if info["osago_date"] is NSNull == false {
                            let osagoDate = info["osago_date"] as! String
                            values[5] = osagoDate
                        }
                        if info["total_fuel"] is NSNull == false {
                            let totalFuel = info["total_fuel"] as! Double
                            values[6] = String(describing: totalFuel)
                        }
                        if info["fuel_date"] is NSNull == false {
                            let fuelDate = info["fuel_date"] as! String
                            values[7] = String(describing: fuelDate)
                        }
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
    
    func deleteTransp(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_transp&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_transp"] as! [String : Any]
                    print("TranspDetailView.deleteTransp(): \(info)")
                    
                    if info["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                    }
                }
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
                alertMessage = "Ошибка"
                showAlert = true
            }
        } else {
            alertMessage = "Ошибка"
            showAlert = true
        }
    }
}
