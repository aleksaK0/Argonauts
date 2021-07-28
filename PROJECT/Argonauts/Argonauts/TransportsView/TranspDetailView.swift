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
    @State var keys: [String] = ["Ник", "Год выпуска", "Пробег", "Моточасы", "Дата диаг. карты", "Дата ОСАГО", "Сум. расход\nтоплива", "Дата отсчета\nтоплива"]
    @State var values: [String] = ["", "", "", "", "", "", "", ""]
    
    @State var showTranspEditDetail: Bool = false
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView(showsIndicators: false) {
                    ForEach(Array(zip(keys, values)), id: \.0) { item in
                        Divider()
                        HStack {
                            Text(item.0)
                                .fontWeight(.semibold)
                                .padding([.leading])
                            Spacer()
                            Text(item.1)
                                .padding([.trailing])
                        }
                    }
                    Button(action: {
                        discardFuelAsync()
                    }, label: {
                        Text("Сбросить топливо")
                            .font(.body)
                    })
                    .padding([.top])
                    Button(action: {
                        alertMessage = "Вы уверены, что хотите удалить данное транспортное средство?"
                        showAlert = true
                    }, label: {
                        Text("Удалить")
                            .font(.body)
                            .foregroundColor(.red)
                    })
                    .padding([.top])
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
        .navigationBarTitle(values[0], displayMode: .inline)
        .navigationBarItems(
            trailing:
                Button(action: {
                    showTranspEditDetail = true
                }, label: {
                    Text("Изм.")
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
        .fullScreenCover(isPresented: $showTranspEditDetail, onDismiss: getTranspAsync) {
            NavigationView {
                TranspDetailEditView(isPresented: $showTranspEditDetail, tid: String(tid), nick: values[0], producted: values[1], diagDate: convertStringToDate(string: values[4]), osagoDate: convertStringToDate(string: values[5]), diagDateStr: values[4], osagoDateStr: values[5], diagDateChanged: values[4] != "", osagoDateChanged: values[5] != "")
                    .environmentObject(globalObj)
            }
        }
        .onAppear {
            getTranspAsync()
        }
    }
    
    func convertStringToDate(string: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "dd.MM.yyyy"
        let date = formatter.date(from: string)
        return date ?? Date()
    }
    
    func reverseDate(date: String) -> String {
        let comp = date.components(separatedBy: "-")
        let revDate = comp[2] + "." + comp[1] + "." + comp[0]
        return revDate
    }
    
    func getTranspAsync() {
        isLoading = true
        values = ["", "", "", "", "", "", "", ""]
        DispatchQueue.global(qos: .userInitiated).async {
            getTransp(tid: String(tid))
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
                if alertMessage == "" {
                    presentationMode.wrappedValue.dismiss()
                }
                isLoading = false
            }
        }
    }
    
    func discardFuelAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            discardFuel(tid: String(tid))
            getTransp(tid: String(tid))
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
    
    func getTransp(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_transp&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_transp"] as! [[String : Any]]
                    print("TranspDetailView.getTransportInfo(): \(info)")
                    
                    if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        values[0] = info[0]["nick"] as! String
                        if info[0]["producted"] is NSNull == false {
                            let producted = info[0]["producted"] as! Int
                            values[1] = String(producted)
                        }
                        if info[0]["mileage"] is NSNull == false {
                            let mileage = info[0]["mileage"] as! Int
                            values[2] = String(mileage)
                        }
                        if info[0]["eng_hour"] is NSNull == false {
                            let engHour = info[0]["eng_hour"] as! Int
                            values[3] = String(engHour)
                        }
                        if info[0]["diag_date"] is NSNull == false {
                            let diagDate = info[0]["diag_date"] as! String
                            values[4] = reverseDate(date: diagDate)
                        }
                        if info[0]["osago_date"] is NSNull == false {
                            let osagoDate = info[0]["osago_date"] as! String
                            values[5] = reverseDate(date: osagoDate)
                        }
                        if info[0]["total_fuel"] is NSNull == false {
                            let totalFuel = info[0]["total_fuel"] as! Double
                            values[6] = String(format: "%.2f", totalFuel)
                        }
                        if info[0]["fuel_date"] is NSNull == false {
                            let fuelDate = info[0]["fuel_date"] as! String
                            values[7] = reverseDate(date: fuelDate)
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
