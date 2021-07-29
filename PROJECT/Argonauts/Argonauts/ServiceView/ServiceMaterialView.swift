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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isExpanded.toggle()
                    }
                    .padding([.leading, .trailing])
                    TextField("Код/наименование детали", text: $matInfo)
                        .disableAutocorrection(true)
                        .padding([.leading, .trailing])
                    TextField("Стоимость детали (доп)", text: $matCost)
                        .keyboardType(.decimalPad)
                        .padding([.leading, .trailing])
                    TextField("Стоимость работы (доп)", text: $wrkCost)
                        .keyboardType(.decimalPad)
                        .padding([.leading, .trailing])
                    Button {
                        UIApplication.shared.endEditing()
                        addMaterialAsync()
                    } label: {
                        Text("Добавить")
                    }
                    .disabled(matInfo.isEmpty)
                }
                if materials.isEmpty {
                    Text("Здесь будет список записей о материалах")
                        .foregroundColor(Color(UIColor.systemGray))
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(materials, id: \.maid) { material in
                            RowMaterial(material: material)
                        }
                        .onDelete(perform: deleteMaterialAsync)
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
        .navigationBarTitle("Детали", displayMode: .inline)
        .navigationBarItems(trailing:
                                Button(action: {
                                    matInfo = ""
                                    matCost = ""
                                    wrkCost = ""
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
            getMaterialAsync()
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
    
    func canAddMaterial() -> Bool {
        if matCost.isEmpty == false && wrkCost.isEmpty == true {
            if isValid(value: matCost) {
                return true
            }
        } else if matCost.isEmpty == true && wrkCost.isEmpty == false {
            if isValid(value: wrkCost) {
                return true
            }
        } else if matCost.isEmpty == false && wrkCost.isEmpty == false {
            if isValid(value: matCost) && isValid(value: wrkCost) {
                return true
            }
        }
        return false
    }
    
    func getMaterialAsync() {
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
            if canAddMaterial() {
                addMaterial(sid: String(sid), matInfo: matInfo, wrkType: wrkType, matCost: matCost.replacingOccurrences(of: ",", with: "."), wrkCost: wrkCost.replacingOccurrences(of: ",", with: "."))
            } else {
                alertMessage = "Введены некорректные данные"
                showAlert = true
            }
            DispatchQueue.main.async {
                if alertMessage == "" {
                    matInfo = ""
                    matCost = ""
                    wrkCost = ""
                }
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
