//
//  LJDateFormatters.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

class LJDateFormatters: NSObject {
    lazy var mediumShortDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

}
