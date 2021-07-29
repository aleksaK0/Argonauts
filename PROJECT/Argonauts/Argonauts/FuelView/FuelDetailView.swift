//
//  RefuelDetailView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 13.07.2021.
//

import SwiftUI

struct FuelDetailView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var tid: Int
    @State var nick: String
    
    @State var alertMessage: String = ""
    @State var date: Date = Date()
    @State var mileage: String = ""
    @State var fuel: String = ""
    @State var fillBrand: String = ""
    @State var fuelBrand: String = ""
    @State var fuelCost: String = ""
    @State var fuels: [Fuel] = []
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    ScrollView(showsIndicators: true) {
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                        TextField("Топливо", text: $fuel)
                            .keyboardType(.decimalPad)
                            .padding([.leading, .trailing])
                        TextField("Пробег", text: $mileage)
                            .keyboardType(.numberPad)
                            .padding([.leading, .trailing])
                        TextField("Бренд заправки (доп)", text: $fillBrand)
                            .disableAutocorrection(true)
                            .padding([.leading, .trailing])
                        TextField("Марка топлива (доп)", text: $fuelBrand)
                            .disableAutocorrection(true)
                            .padding([.leading, .trailing])
                        TextField("Стоимость 1 литра (доп)", text: $fuelCost)
                            .keyboardType(.decimalPad)
                            .padding([.leading, .trailing])
                        Button {
                            UIApplication.shared.endEditing()
                            addFuelAsync()
                        } label: {
                            Text("Добавить")
                        }
                        .disabled(fuel.isEmpty || mileage.isEmpty)
                        .padding([.bottom], 70)
                    }
                    .frame(height: UIScreen.main.bounds.height / 1.5)
                    Spacer()
                }
                if fuels.isEmpty {
                    Text("Здесь будет список записей о заправках")
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(fuels, id: \.fid) { fuel in
                            RowFuel(fuel: fuel)
                        }
                        .onDelete(perform: deleteFuelAsync)
                    }
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
        .navigationBarTitle(nick, displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    fuel = ""
                                    mileage = ""
                                    fillBrand = ""
                                    fuelBrand = ""
                                    fuelCost = ""
                                    showFields.toggle()
                                }, label: {
                                    if showFields {
                                        Image(systemName: "minus")
                                            .font(.title2.weight(.semibold))
                                    } else {
                                        Image(systemName: "plus")
                                            .font(.title2.weight(.semibold))
                                    }
                                }))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getFuelAsync()
        }
    }
    
    func isValidMileage(mileage: String) -> Bool {
        do {
            let regEx = "^[0-9]{1,9}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = mileage as NSString
            let results = regex.matches(in: mileage, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    
    func isValid(value: String) -> Bool {
        do {
            let regEx = "^[0-9]{1,9}+[',']{0,1}+[0-9]{0,2}$"
            let regex = try NSRegularExpression(pattern: regEx)
            let nsString = value as NSString
            let results = regex.matches(in: value, range: NSRange(location: 0, length: nsString.length))
            if results.count != 1 {
                return false
            }
            return true
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
        
    }
    
    func canAddFuel() -> Bool {
        if isValidMileage(mileage: mileage) && isValid(value: fuel) {
            if fuelCost.isEmpty == false {
                if isValid(value: fuelCost) {
                    return true
                }
            } else {
                return true
            }
        }
        return false
    }
    
    func getFuelAsync() {
        isLoading = true
        fuels = []
        DispatchQueue.global(qos: .userInitiated).async {
            getFuel(tid: String(tid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func addFuelAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if canAddFuel() {
                addFuel(tid: String(tid), date: date, fuel: fuel.replacingOccurrences(of: ",", with: "."), mileage: mileage, fillBrand: fillBrand, fuelBrand: fuelBrand, fuelCost: fuelCost.replacingOccurrences(of: ",", with: "."))
            } else {
                alertMessage = "Введены некорректные данные"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    fuel = ""
                    mileage = ""
                    fillBrand = ""
                    fuelBrand = ""
                    fuelCost = ""
                }
                isLoading = false
            }
        }
    }
    
    func deleteFuelAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let fid = fuels[index].fid
            deleteFuel(fid: String(fid), tid: String(tid))
            DispatchQueue.main.async {
                if alertMessage == "" {
                    fuels.remove(at: index)
                }
                isLoading = false
            }
        }
    }
    
    func getFuel(tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_fuel&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_fuel"] as! [[String : Any]]
                    print("FuelDetailView.getFuel(): \(info)")
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            var date = el["date"] as! String
                            date = date.replacingOccurrences(of: "T", with: " ")
                            date.removeLast(3)
                            let fuel = Fuel(fid: el["fid"] as! Int, date: date, fuel: el["fuel"] as! Double, mileage: el["mileage"] as? Int, fillBrand: el["fill_brand"] as? String, fuelBrand: el["fuel_brand"] as? String, fuelCost: el["fuel_cost"] as? Double)
                            fuels.append(fuel)
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
    
    func addFuel(tid: String, date: Date, fuel: String, mileage: String, fillBrand: String, fuelBrand: String, fuelCost: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: date)
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_fuel&tid=" + tid + "&date=" + dateString + "&mileage=" + mileage + "&fuel=" + fuel + "&fill_brand=" + fillBrand + "&fuel_brand=" + fuelBrand + "&fuel_cost=" + fuelCost
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_fuel"] as! [String : Any]
                    print("FuelDetailView.addFuel(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Запись с таким временем/пробегом уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else if info["fid"] == nil {
                        alertMessage = "Введены некорректные данные"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        let fuel = Fuel(fid: info["fid"] as! Int, date: info["date"] as! String, fuel: info["fuel"] as! Double, mileage: info["mileage"] as? Int, fillBrand: info["fill_brand"] as? String, fuelBrand: info["fuel_brand"] as? String, fuelCost: info["fuel_cost"] as? Double)
                        fuels.append(fuel)
                        fuels.sort { $0.date > $1.date }
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
    
    func deleteFuel(fid: String, tid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_fuel&fid=" + fid + "&tid=" + tid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_fuel"] as! [String : Any]
                    print("FuelDetailView.deleteFuel(): \(info)")
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
