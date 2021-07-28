//
//  ServiceMaterialView.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 15.07.2021.
//

import SwiftUI

struct ServiceMaterialView: View {
    @EnvironmentObject var globalObj: GlobalObj
    @State var sid: Int
    
    @State var alertMessage: String = ""
    @State var matInfo: String = ""
    @State var wrkType: String = "Замена"
    @State var matCost: String = ""
    @State var wrkCost: String = ""
    @State var wrkTypes: [String] = ["Замена", "Ремонт", "Окраска", "Снятие/установка", "Регулировка"]
    @State var serviceKeys: [String] = ["Дата", "Тип работ", "Пробег", "Цена деталей", "Цена работ"]
    @State var serviceInfo: [String] = ["", "", "", "", ""]
    @State var service: Service = Service(sid: 0, date: "", serType: "", mileage: 0, matCost: nil, wrkCost: nil)
    @State var materials: [Material] = []
    
    @State var showAlert: Bool = false
    @State var isLoading: Bool = false
    @State var showFields: Bool = false
    @State var isExpanded: Bool = false
    
    @State var pad: CGFloat = 5
    
    var body: some View {
        ZStack {
            VStack {
                if showFields {
                    DisclosureGroup("Тип работы: \(wrkType)", isExpanded: $isExpanded) {
                        ForEach(wrkTypes, id: \.self) { el in
                            HStack {
                                Spacer()
                                Text(el)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                wrkType = el
                                isExpanded = false
                            }
                            Divider()
                        }
                    }
                    TextField("Код/наименование детали", text: $matInfo)
                    TextField("Стоимость детали", text: $matCost)
                        .keyboardType(.decimalPad)
                    TextField("Стоимость работы", text: $wrkCost)
                        .keyboardType(.decimalPad)
                    Button {
                        UIApplication.shared.endEditing()
                        addMaterialAsync()
                    } label: {
                        Text("Добавить")
                    }
                }
                List {
                    ForEach(materials, id: \.maid) { material in
                        RowMaterial(material: material)
                    }
                    .onDelete(perform: deleteMaterialAsync)
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
        .navigationBarTitle("Детали", displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    showFields.toggle()
                                }, label: {
                                    if showFields {
                                        Image(systemName: "minus")
                                    } else {
                                        Image(systemName: "plus")
                                    }
                                }))
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage))
        }
        .onAppear {
            getServiceInfoAsync()
            loadDataAsync()
        }
    }
    
    func getServiceInfoAsync() {
        isLoading = true
//        serviceInfo = ["", "", "", "", ""]
        DispatchQueue.global(qos: .userInitiated).async {
            getServiceInfo(sid: String(sid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func loadDataAsync() {
        isLoading = true
        materials = []
        DispatchQueue.global(qos: .userInitiated).async {
            getMaterial(sid: String(sid))
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func addMaterialAsync() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            addMaterial(sid: String(sid), matInfo: matInfo, wrkType: wrkType, matCost: matCost, wrkCost: wrkCost)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    func deleteMaterialAsync(at offsets: IndexSet) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let index = offsets[offsets.startIndex]
            let maid = materials[index].maid
            deleteMaterial(maid: String(maid))
            DispatchQueue.main.async {
                if alertMessage == "" {
                    materials.remove(at: index)
                }
                isLoading = false
            }
        }
    }
    
    func getServiceInfo(sid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_service_info&sid=" + sid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_service_info"] as! [[String : Any]]
                    print("ServiceDetailView.getService(): \(info)")
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
                            
                            date = reverseDateTime(date: date)
                            
                            service = Service(sid: el["sid"] as! Int, date: date, serType: el["ser_type"] as! String, mileage: el["mileage"] as! Int, matCost: el["mat_cost"] as? Double, wrkCost: el["wrk_cost"] as? Double)
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
    
    func getMaterial(sid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_material&sid=" + sid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["get_material"] as! [[String : Any]]
                    print("ServiceMaterialView.getMaterial(): \(info)")
                    
                    if info.isEmpty {
                        // empty
                    } else if info[0]["server_error"] != nil {
                        alertMessage = "Ошибка сервера"
                        showAlert = true
                    } else {
                        alertMessage = ""
                        for el in info {
                            let material = Material(maid: el["maid"] as! Int, matInfo: el["mat_info"] as! String, wrkType: el["wrk_type"] as! String, matCost: el["mat_cost"] as? Double, wrkCost: el["wrk_cost"] as? Double)
                            materials.append(material)
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
    
    func addMaterial(sid: String, matInfo: String, wrkType: String, matCost: String, wrkCost: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=add_material&sid=" + sid + "&mat_info=" + matInfo + "&wrk_type=" + wrkType + "&mat_cost=" + matCost + "&wrk_cost=" + wrkCost
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["add_material"] as! [String : Any]
                    print("ServiceMaterialView.addMaterial(): \(info)")
                    
                    if info["server_error"] != nil {
                        if info["err_code"] as! Int == 1062 {
                            alertMessage = "Деталь с таким названием уже есть"
                            showAlert = true
                        } else {
                            alertMessage = "Ошибка сервера"
                            showAlert = true
                        }
                    } else {
                        alertMessage = ""
                        materials.append(Material(maid: info["maid"] as! Int, matInfo: info["mat_info"] as! String, wrkType: info["wrk_type"] as! String, matCost: info["mat_cost"] as? Double, wrkCost: info["wrk_cost"] as? Double))
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
    
    func deleteMaterial(maid: String) {
        let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=delete_material&maid=" + maid
        let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let url = URL(string: encodedUrl!)
        if let data = try? Data(contentsOf: url!) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let info = json["delete_material"] as! [String : Any]
                    print("ServiceMaterialView.deleteMaterial(): \(info)")
                    
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
