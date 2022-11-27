//
//  DispatchTime+format.swift
//  mt-test-1
//
//  Created by Kevin Bein on 26.11.22.
//

import Dispatch

extension DispatchTime: Identifiable {
    public var id: UInt64 { self.uptimeNanoseconds }
    
    func format(differenceTo: DispatchTime? = nil) -> Double {
        var nanoTime = self.uptimeNanoseconds
        if differenceTo != nil {
            nanoTime = max(differenceTo!.uptimeNanoseconds, self.uptimeNanoseconds)
                     - min(differenceTo!.uptimeNanoseconds, self.uptimeNanoseconds)
        }
        return Double(nanoTime) / 1_000_000_000
    }
}
