//
//  Fret.swift
//  MyTuna
//
//  Created by Luca Cipressi on 20180411.
//  Copyright © 2018 Lookaji. All rights reserved.
//

import Foundation

@objc
enum Fret: Int {
    static let allFrets = [.fret5, fret7, fret12, .openStrings]
    
    case openStrings = 0
    case fret5 = 5
    case fret7 = 7
    case fret12 = 12
    
    func shiftDown(frequency: Double) -> Double {
        return frequency / pow(2.0, Double(self.rawValue) / 12.0)
    }
    
    func shiftUp(frequency: Double) -> Double {
        return frequency * pow(2.0, Double(self.rawValue) / 12.0)
    }
    
    func localized() -> String {
        switch self {
        case .openStrings: return "Open strings".localized()
        default:
            return String(format: "%ith fret", self.rawValue).localized()
        }
    }
    
    var description : String { return localized() }
}

