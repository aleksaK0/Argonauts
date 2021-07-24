//
//  StatisticsDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 24.07.2021.
//

import SwiftUI


//"fuel_avg": 30.1,
//      "fuel_cnt": 8,
//      "fuel_max": 41.58,
//      "fuel_min": 17.02,
//      "mm": 5,
//      "mo": "2021 май",
//      "tid": 121,
//      "yy": 2021

struct StatisticsDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    @State var selection: Int = 0
    @State var currItem: Int = 0
    
    @State var statisticsFuel: [StatisticsFuel] = []
    
    @State var isLoading: Bool = true
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Picker("", selection: $selection) {
                    Text("Mecяцы").tag(0)
                    Text("Годы").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.leading, .trailing, .top])
                .onChange(of: selection) { value in
                    currItem = 0
//                    statisticsFuel = []
                    getStatisticsFuelAsync()
                }
                HStack {
                    Button(action: {
                        currItem -= 1
                    }, label: {
                        Image(systemName: "chevron.backward")
                    })
                    .disabled(currItem == 0)
                    TabView(selection: $currItem) {
                        ForEach(statisticsFuel, id: \.id) { statistics in
                            Text(statistics.mo).tag(statistics.id)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: UIScreen.main.bounds.width - 120, height: UIScreen.main.bounds.height / 6, alignment: .center)
                    Button(action: {
                        currItem += 1
                    }, label: {
                        Image(systemName: "chevron.forward")
                    })
                    .disabled(currItem == statisticsFuel.count - 1)
                }
                if !statisticsFuel.isEmpty {
                    Group {
                        Text("Топливо")
                        Text("Cnt \(statisticsFuel[currItem].fuelCnt)")
                        Text("Min \(statisticsFuel[currItem].fuelMin)")
                        Text("Max \(statisticsFuel[currItem].fuelMax)")
                        Text("Avg \(statisticsFuel[currItem].fuelAvg)")
                    }
                } else {
                    Text("Статистика недоступна")
                }
                Spacer()
            }
            if isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .allowsHitTesting(true)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            }
        }
        .navigationBarTitle(nick, displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getStatisticsFuelAsync()
            print("onAppear \(statisticsFuel.count)")
        }
    }
    
    func getStatisticsFuelAsync() {
        isLoading = true
        statisticsFuel = []
        DispatchQueue.global(qos: .userInitiated).async {
            if selection == 0 {
                getStatisticsFym(tid: String(tid))
            } else {
                getStatisticsFyy(tid: String(tid))
            }
            DispatchQueue.main.async {
//                print("getStatisticsFuelAsync \(currItem)")
                if alertMessage == "" {
                    currItem = statisticsFuel.count - 1
                }
//                print("getStatisticsFuelAsync \(currItem)")
                isLoading = false
            }
        }
    }
    
    func getStatisticsFym(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_statistics_fym&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_statistics_fym"] as! [[String : Any]]
                    print("StatisticsDetailView.getStatisticsFym(): \(info)")
                    if info.isEmpty {
                        
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        var id: Int = 0
                        for el in info {
                            let statistics = StatisticsFuel(id: id, tid: el["tid"] as! Int, yy: el["yy"] as! Int, mm: el["mm"] as! Int, mo: el["mo"] as! String, fuelMin: el["fuel_min"] as! Double, fuelMax: el["fuel_max"] as! Double, fuelAvg: el["fuel_avg"] as! Double, fuelCnt: el["fuel_cnt"] as! Int)
                            statisticsFuel.append(statistics)
                            id += 1
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
    
    func getStatisticsFyy(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_statistics_fyy&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_statistics_fyy"] as! [[String : Any]]
//                    print("StatisticsDetailView.getStatisticsFym(): \(info)")
                    if info.isEmpty {
                        
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        var id: Int = 0
                        for el in info {
                            let statisctics = StatisticsFuel(id: id, tid: el["tid"] as! Int, yy: el["yy"] as! Int, mm: el["mm"] as! Int, mo: el["mo"] as! String, fuelMin: el["fuel_min"] as! Double, fuelMax: el["fuel_max"] as! Double, fuelAvg: el["fuel_avg"] as! Double, fuelCnt: el["fuel_cnt"] as! Int)
//                            statisticsFyy.append(statisctics)
                            statisticsFuel.append(statisctics)
                            id += 1
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
}
