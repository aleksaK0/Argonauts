//
//  File.swift
//  Argonauts
//
//  Created by Aleksa Khruleva on 23.06.2021.
//

import Foundation
import SwiftUI
import LocalAuthentication

enum numPadButton: String {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case zero = "0"
    
    case bio = "bio"
    case del = "del"
    case dop = "dop"
}

enum Views: String {
    case enterEmail = "EnterEmailView"
    case enterPassCode = "EnterPassCodeView"
    case setPin = "SetPinView"
    case repeatPin = "RepeatPinView"
    case createAccount = "CreateAccountView"
    case addTransp = "AddTranspView"
    case home = "HomeView"
    case enterPin = "EnterPinView"
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

func generatePassCode() -> String {
    let passCode = String(Int.random(in: 1000...9999))
    return passCode
}

func writeToDocDir(filename: String, text: String) {
    let ext = "txt"
    let docDirUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let fileUrl = docDirUrl.appendingPathComponent(filename).appendingPathExtension(ext)
    
    do {
        try text.write(to: fileUrl, atomically: true, encoding: String.Encoding.utf8)
    } catch let error as NSError {
        print("writeToDocDir(): error \(error)")
    }
}

extension String {
   var isNumeric: Bool {
     return !(self.isEmpty) && self.allSatisfy { $0.isNumber }
   }
}

func isValidEmailAddress(email: String) -> Bool {
    var isValid: Bool = true
    do {
        let emailRegEx =  "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let regex = try NSRegularExpression(pattern: emailRegEx)
        let nsString = email as NSString
        let results = regex.matches(in: email, range: NSRange(location: 0, length: nsString.length))
        if results.count != 1 { isValid = false }
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        isValid = false
    }
    return isValid
}

func convertDateToString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let str = formatter.string(from: date)
    return str
}

func getTidTnick(email: String, alertMessage: inout String, showAlert: inout Bool, transports: inout [Transport]) {
    let urlString = "https://www.argonauts.online/ARGO63/wsgi?mission=get_tid_tnick&email=" + email
    let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    let url = URL(string: encodedUrl!)
    if let data = try? Data(contentsOf: url!) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let info = json["tid_nick"] as! [[String : Any]]
                print("TransportsView.getTidTnick(): \(info)")
                if info.isEmpty {
                    // empty
                } else if info[0]["server_error"] != nil {
                    alertMessage = "Ошибка сервера"
                    showAlert = true
                } else {
                    alertMessage = ""
                    for el in info {
                        let transport = Transport(tid: el["tid"] as! Int, nick: el["nick"] as! String, producted: nil, mileage: nil, engHours: nil, diagDate: nil, osagoDate: nil, totalFuel: nil, fuelDate: nil)
                        transports.append(transport)
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

let buttonsNoBio: [[numPadButton]] = [
    [.one, .two, .three],
    [.four, .five, .six],
    [.seven, .eight, .nine],
    [.dop, .zero, .del],
]

let buttonsWithBio: [[numPadButton]] = [
    [.one, .two, .three],
    [.four, .five, .six],
    [.seven, .eight, .nine],
    [.bio, .zero, .del],
]

class GlobalObj: ObservableObject {
    var email: String = ""
    var biometryType: String = ""
    var isEmailExists: Bool = false
    var tidCurr: Int = 0
    var tids: [Int] = []
    var sentPassCode: String = ""
    var pin: String = ""
}

class Transport: ObservableObject, Identifiable {
    var tid: Int
    var nick: String
    var producted: Int?
    var mileage: Int?
    var engHours: Int?
    var diagDate: Date?
    var osagoDate: Date?
    var totalFuel: Double?
    var fuelDate: Date?
    
    init(tid: Int, nick: String, producted: Int?, mileage: Int?, engHours: Int?, diagDate: Date?, osagoDate: Date?, totalFuel: Double?, fuelDate: Date?) {
        self.tid = tid
        self.nick = nick
        self.producted = producted
        self.mileage = mileage
        self.engHours = engHours
        self.diagDate = diagDate
        self.osagoDate = osagoDate
        self.totalFuel = totalFuel
        self.fuelDate = fuelDate
    }
}

class Email {
    var eid: Int
    var email: String
    var send: Int
    
    init(eid: Int, email: String, send: Int) {
        self.eid = eid
        self.email = email
        self.send = send
    }
}

class Mileage {
    var mid: Int
    var date: String
    var mileage: Int
    
    init(mid: Int, date: String, mileage: Int) {
        self.mid = mid
        self.date = date
        self.mileage = mileage
    }
}

class EngHour {
    var ehid: Int
    var date: String
    var engHour: Int
    
    init(ehid: Int, date: String, engHour: Int) {
        self.ehid = ehid
        self.date = date
        self.engHour = engHour
    }
}

class Fuel {
    var fid: Int
    var date: String
    var fuel: Double
    var mileage: Int?
    var fillBrand: String?
    var fuelBrand: String?
    var fuelCost: Double?
    
    init(fid: Int, date: String, fuel: Double, mileage: Int?, fillBrand: String?, fuelBrand: String?, fuelCost: Double?) {
        self.fid = fid
        self.date = date
        self.fuel = fuel
        self.mileage = mileage
        self.fillBrand = fillBrand
        self.fuelBrand = fuelBrand
        self.fuelCost = fuelCost
    }
}

class Service {
    var sid: Int
    var date: String
    var serType: String
    var mileage: Int
    var matCost: Double?
    var wrkCost: Double?
    
    init(sid: Int, date: String, serType: String, mileage: Int, matCost: Double?, wrkCost: Double?) {
        self.sid = sid
        self.date = date
        self.serType = serType
        self.mileage = mileage
        self.matCost = matCost
        self.wrkCost = wrkCost
    }
}

class Material {
    var maid: Int
    var matInfo: String
    var wrkType: String
    var matCost: Double?
    var wrkCost: Double?
    
    init(maid: Int, matInfo: String, wrkType: String, matCost: Double?, wrkCost: Double?) {
        self.maid = maid
        self.matInfo = matInfo
        self.wrkType = wrkType
        self.matCost = matCost
        self.wrkCost = wrkCost
    }
}

class Notification {
    var nid: Int
    var tid: Int
    var type: String
    var mode: Int
    var date: String?
    var value1: Int?
    var value2: Int?
    var notification: String
    
    init(nid: Int, tid: Int, type: String, mode: Int, date: String?, value1: Int?, value2: Int?, notification: String) {
        self.nid = nid
        self.tid = tid
        self.type = type
        self.mode = mode
        self.date = date
        self.value1 = value1
        self.value2 = value2
        self.notification = notification
    }
}

struct StatisticsFuel {
    var id: Int
    var tid: Int
    var yy: Int
    var mm: Int
    var mo: String
    var fuelMin: Double
    var fuelMax: Double
    var fuelAvg: Double
    var fuelCnt: Int
}

//    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification), perform: { _ in
//        isUnlocked = false
//    })
//    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
//        authenticate()
//    })

func buttonWidthNumPad(item: numPadButton) -> CGFloat {
    return (UIScreen.main.bounds.width - (5 * 12)) / 4
}

func buttonHeightNumPad(item: numPadButton) -> CGFloat {
    return (UIScreen.main.bounds.width - (5 * 12)) / 4
}

func feedbackSelect() {
//    let impactLight = UIImpactFeedbackGenerator(style: .light)
//    impactLight.impactOccurred()
    let selectionFeedback = UISelectionFeedbackGenerator()
    selectionFeedback.selectionChanged()
}

func feedbackError() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.error)
}



func getBioType() {
    let context = LAContext()
    var error: NSError?

    // check whether biometric authentication is possible
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        switch context.biometryType {
        case .faceID:
            print("authenticate: faceID")
//            globalObj.biometryType = "faceID"
        case .touchID:
            print("authenticate: touchID")
//            globalObj.biometryType = "touchID"
        default:
            print("authenticate: none")
//            globalObj.biometryType = "none"
        }
    } else {
//        globalObj.biometryType = "none"
    }
}
