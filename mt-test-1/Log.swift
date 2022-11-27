//
//  Log.swift
//  mt-test-1
//
//  Created by Kevin Bein on 24.11.22.
//

import Foundation

class Log {
    static func uiPrint(key: String, value: Any?) {
        let output = [
            "key": key,
            "value": value
        ]
        NotificationCenter.default.post(name: Notification.Name("LogUIPrint"), object: nil, userInfo: output as [AnyHashable : Any])
    }
    
    static func getSaved(from: String, lastSessionOnly: Bool = false) -> [[String]] {
        guard let saved = UserDefaults.standard.array(forKey: from) else { return [] }
        
        var final: [[String]] = []
        for item in saved {
            guard let stringArray = item as? [String] else { continue }
            final.append(stringArray.map { entry in entry as! String })
        }
        
        if lastSessionOnly {
            guard let lastEntry = final.last else { return final }
            let uniqueRunSessionId = lastEntry[0]
            var finalLastSessionOnly: [[String]] = []
            for item in final.reversed() {
                if item[0] == uniqueRunSessionId {
                    finalLastSessionOnly.append(item)
                }
            }
            return finalLastSessionOnly
        }
        
        return final
    }
    
    static func print(_ items: Any..., separator: String = " ", saveTo: String? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"
        let date = Date()
        let timestamp = dateFormatter.string(from: date)
        
        Swift.print( "[ARcessible][\(timestamp)]", separator: separator, terminator: " ")
        for item in items {
            Swift.print(item, separator: separator, terminator: " ")
        }
        Swift.print("")
        
        if saveTo != nil {
            guard let uniqueRunSessionId = UserDefaults.standard.string(forKey: "lastRunSessionId")
            else {
                fatalError("Missing unique run session id!")
            }
            
            var data: [String] = [ uniqueRunSessionId, timestamp ]
            for item in items {
                data.append(item as! String)
            }
            
            var storedArray = UserDefaults.standard.array(forKey: saveTo!)
            if storedArray == nil {
                storedArray = []
            }
            storedArray!.append(data)
            UserDefaults.standard.set(storedArray!, forKey: saveTo!)
        }
    }
}
