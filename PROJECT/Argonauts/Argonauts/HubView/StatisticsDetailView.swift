//
//  StatisticsDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 24.07.2021.
//

import SwiftUI

struct StatisticsDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    @State var selection: Int = 0
    @State var currItem: Int = 0
    @State var statistics: [Statistics] = []
    
    
    @State var isLoading: Bool = false
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
                    getStatistics()
                }
                HStack {
                    Button(action: {
                        currItem -= 1
                    }, label: {
                        Image(systemName: "chevron.backward")
                            .font(.title.weight(.semibold))
                            .frame(width: UIScreen.main.bounds.width / 8, height: UIScreen.main.bounds.height / 8, alignment: .center)
                    })
                    .disabled(statistics.isEmpty || currItem == 0)
                    TabView(selection: $currItem) {
                        ForEach(statistics, id: \.id) { statistics in
                            Text(statistics.mo)
                                .font(.title2)
                                .tag(statistics.id)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(width: UIScreen.main.bounds.width - 120, height: UIScreen.main.bounds.height / 8, alignment: .center)
                    Button(action: {
                        currItem += 1
                    }, label: {
                        Image(systemName: "chevron.forward")
                            .font(.title.weight(.semibold))
                            .frame(width: UIScreen.main.bounds.width / 8, height: UIScreen.main.bounds.height / 8, alignment: .center)
                    })
                    .disabled(currItem == statistics.count - 1 || statistics.isEmpty)
                }
                if !statistics.isEmpty {
                    ScrollView(showsIndicators: false) {
                        HStack {
                            Text("Топливо")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        .padding([.bottom], 10)
                        Group {
                            HStack {
                                Text("Кол-во заправок")
                                Spacer()
                                Text(String(describing: statistics[currItem].fuelCnt))
                            }
                            Divider()
                            HStack {
                                Text("Средняя заправка")
                                Spacer()
                                Text(String(describing: statistics[currItem].fuelAvg))
                            }
                            Divider()
                            HStack {
                                Text("Сум. заправка")
                                Spacer()
                                Text(String(describing: statistics[currItem].fuelSum))
                            }
                            Divider()
                            HStack {
                                Text("Мин. заправка")
                                Spacer()
                                Text(String(describing: statistics[currItem].fuelMin))
                            }
                            Divider()
                            HStack {
                                Text("Макс. заправка")
                                Spacer()
                                Text(String(describing: statistics[currItem].fuelMax))
                            }
                        }
                        HStack {
                            Text("Пробег")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        .padding([.top, .bottom], 10)
                        Group {
                            HStack {
                                Text("Кол-во записей")
                                Spacer()
                                Text(String(describing: statistics[currItem].mileageCnt))
                            }
                            Divider()
                            HStack {
                                Text("Средний пробег")
                                Spacer()
                                Text(String(describing: statistics[currItem].mileageAvg))
                            }
                            Divider()
                            HStack {
                                Text("Сум. пробег")
                                Spacer()
                                Text(String(describing: statistics[currItem].mileageSum))
                            }
                            Divider()
                            HStack {
                                Text("Мин. пробег")
                                Spacer()
                                Text(String(describing: statistics[currItem].mileageMin))
                            }
                            Divider()
                            HStack {
                                Text("Макс. пробег")
                                Spacer()
                                Text(String(describing: statistics[currItem].mileageMax))
                            }
                        }
                        HStack {
                            Text("Топливо/Пробег")
                                .font(.title2.weight(.bold))
                            Spacer()
                        }
                        .padding([.top, .bottom], 10)
                        HStack {
                            Text("Сум.?? Может Средний?")
                            Spacer()
                            Text(String(describing: statistics[currItem].fmSum))
                        }
                    }
                    .padding([.leading, .trailing])
                } else {
                    Text("Статистика недоступна")
                        .foregroundColor(Color(UIColor.systemGray))
                }
                Spacer()
            }
            if isLoading {
                Rectangle()
                    .fill(Color.loadingColor.opacity(0.5))
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
            getStatistics()
            print("onAppear \(statistics.count)")
        }
    }
    
    func getStatistics() {
        isLoading = true
        statistics = []
        DispatchQueue.global(qos: .userInitiated).async {
            if selection == 0 {
                getStatisticsMonth(tid: String(tid))
            } else {
                getStatisticsYear(tid: String(tid))
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    currItem = statistics.count - 1
                }
                isLoading = false
            }
        }
    }
    
    func getStatisticsMonth(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_statistics_month&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_statistics_month"] as! [[String : Any]]
                    print("StatisticsDetailView.getStatisticsFym(): \(info)")
                    if info.isEmpty {
                        
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        var id: Int = 0
                        for el in info {
                            let statistics = Statistics(id: id, tid: el["tid"] as! Int, mo: el["mo"] as! String, fuelCnt: el["fuel_cnt"] as! String, fuelSum: el["fuel_sum"] as! String, fuelMin: el["fuel_min"] as! String, fuelMax: el["fuel_max"] as! String, fuelAvg: el["fuel_avg"] as! String, mileageCnt: el["mileage_cnt"] as! String, mileageSum: el["mileage_sum"] as! String, mileageMin: el["mileage_min"] as! String, mileageMax: el["mileage_max"] as! String, mileageAvg: el["mileage_avg"] as! String, fmSum: el["fm_sum"] as! String)
                            self.statistics.append(statistics)
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
    
    func getStatisticsYear(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_statistics_year&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_statistics_year"] as! [[String : Any]]
                    print("StatisticsDetailView.getStatisticsFym(): \(info)")
                    if info.isEmpty {
                        
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        var id: Int = 0
                        for el in info {
                            let statistics = Statistics(id: id, tid: el["tid"] as! Int, mo: el["mo"] as! String, fuelCnt: el["fuel_cnt"] as! String, fuelSum: el["fuel_sum"] as! String, fuelMin: el["fuel_min"] as! String, fuelMax: el["fuel_max"] as! String, fuelAvg: el["fuel_avg"] as! String, mileageCnt: el["mileage_cnt"] as! String, mileageSum: el["mileage_sum"] as! String, mileageMin: el["mileage_min"] as! String, mileageMax: el["mileage_max"] as! String, mileageAvg: el["mileage_avg"] as! String, fmSum: el["fm_sum"] as! String)
                            self.statistics.append(statistics)
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
