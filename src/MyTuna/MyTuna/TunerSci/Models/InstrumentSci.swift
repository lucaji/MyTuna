//
//  Instrument.swift
//  SciTuner
//
//  Created by Denis Kreshikhin on 8/9/17.
//  Copyright © 2017 Denis Kreshikhin. All rights reserved.
//

import Foundation

enum InstrumentSci: String {
    case guitar = "guitar"
    case cello = "cello"
    case violin = "violin"
    case banjo = "banjo"
    case balalaika = "balalaika"
    case ukulele = "ukulele"
    
    static let all: [InstrumentSci] = [.guitar, .cello, .violin, .banjo, .balalaika, .ukulele]
    
    func localized() -> String {
        return rawValue.localized()
    }
    
    func tunings() -> [TuningSci] {
        switch self {
        case .guitar: return TuningSci.guitarTunings
        case .cello: return TuningSci.celloTunings
        case .violin: return TuningSci.violinTunings
        case .banjo: return TuningSci.banjoTunings
        case .balalaika: return TuningSci.balalaikaTunings
        case .ukulele: return TuningSci.ukuleleTunings
        }
    }
}
