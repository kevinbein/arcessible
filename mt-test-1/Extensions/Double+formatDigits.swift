//
//  Double+formatDigits.swift
//  mt-test-1
//
//  Created by Kevin Bein on 26.11.22.
//

extension Double {
    func formatDigits(_ count: Int) -> String {
        return String(format: "%.\(count)f", self)
    }
}
