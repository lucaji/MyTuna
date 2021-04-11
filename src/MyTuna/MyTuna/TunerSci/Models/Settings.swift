//
//  Settings.swift
//  SciTuner
//
//  Created by Denis Kreshikhin on 8/9/17.
//  Copyright © 2017 Denis Kreshikhin. All rights reserved.
//

import Foundation
import AudioKit

class Settings: NSObject {
    typealias `Self` = Settings
    
    static let processingPointCount: UInt = 128
    static var sampleRate : Double {
        get {
            return AKSettings.sampleRate
        }
    }
    static let sampleCount: Int = 2048
    static let spectrumLength: Int = 32768
    static let showFPS = true
    static let previewLength: Int = 5000
    
    static let fMin: Double = 16.0
    static let fMax: Double = Self.sampleRate / 2.0
    
    var fret: Fret = .openStrings
    var stringIndex: Int = 0
    
    var pitch: Pitch {
        set { self.pitch_ = newValue.rawValue }
        get { return Pitch(rawValue: self.pitch_) ?? .standard }
    }
    
    var instrument: InstrumentSci {
        set { self.instrument_ = newValue.rawValue }
        get { return InstrumentSci(rawValue: self.instrument_) ?? .guitar }
    }
    
    var tuning: TuningSci {
        set { self.tuning_ = newValue.id }
        get { return TuningSci(instrument: instrument, id: self.tuning_) ?? TuningSci(standard: instrument)}
    }
    
//    var filter: Filter {
//        set { self.filter_ = newValue.rawValue }
//        get { return Filter(rawValue: self.filter_) ?? .on }
//    }
    
    private var pitch_: String = Pitch.standard.rawValue
    private var instrument_: String = InstrumentSci.guitar.rawValue
    private var tuning_: String = InstrumentSci.guitar.rawValue
//    private var filter_: String = Filter.off.rawValue
    
    static func shared() -> Settings {        
        let settings = Settings()
        return settings
    }
}
