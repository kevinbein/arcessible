//
//  Log.swift
//  mt-test-1
//
//  Created by Kevin Bein on 24.11.22.
//

import Foundation

class Log {
    static func print(_ items: Any...) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"
        let date = Date()
        let timestamp = dateFormatter.string(from: date)
        
        Swift.print("[\(timestamp)]", terminator: " ")
        for item in items {
            Swift.print(item, terminator: " ")
        }
        Swift.print("")
    }
}
