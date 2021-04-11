//
//  LJNumberFormatters.swift
//  MyTuna
//
//  Created by Luca Cipressi on 25/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

class LJNumberFormatters: NSObject {

}

extension NumberFormatter {
    convenience init(style: Style) {
        self.init()
        numberStyle = style
    }
}

extension Formatter {
    static let currency = NumberFormatter(style: .currency)
    static let currencyUS: NumberFormatter = {
        let formatter = NumberFormatter(style: .currency)
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    static let currencyBR: NumberFormatter = {
        let formatter = NumberFormatter(style: .currency)
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()
    
    static let frequency : NumberFormatter = {
        let formatter = NumberFormatter(style: NumberFormatter.Style.decimal)
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}


extension Numeric {   // for Swift 3 use FloatingPoint or Int
    var currency: String {
        return Formatter.currency.string(for: self) ?? ""
    }
    var currencyUS: String {
        return Formatter.currencyUS.string(for: self) ?? ""
    }
    var currencyBR: String {
        return Formatter.currencyBR.string(for: self) ?? ""
    }
    
}
