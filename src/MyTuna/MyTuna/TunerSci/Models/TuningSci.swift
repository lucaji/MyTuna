//
//  Tuning.swift
//  SciTuner
//
//  Created by Denis Kreshikhin on 8/10/17.
//  Copyright © 2017 Denis Kreshikhin. All rights reserved.
//

import Foundation

struct TuningSci: Equatable {
    typealias `Self` = TuningSci
    
    let id: String
    let strings: [MTPitchedNote]
    let description: String
    
    func localized() -> String {
        return id.localized() + " (" + description + ")"
    }
    
    init(_ id: String, _ strings: String) {
        self.id = id
        
        let splitStrings: [String] = strings.characters.split {$0 == " "}.map { String($0) }
        
        self.description = splitStrings.map({(note: String) -> String in
            note.replacingOccurrences(of: "#", with: "♯")
        }).joined(separator: " ")
        
        self.strings = splitStrings.map() { (name: String) -> MTPitchedNote in
            return MTPitchedNote(withMidiNoteName:name)!
        }
    }
    
    init?(instrument: InstrumentSci, id: String) {
        let tunings = instrument.tunings()
        
        guard let tuning = tunings.filter({ $0.id == id}).first else {
            return nil
        }
        
        self = tuning
    }
    
    init(standard instrument: InstrumentSci) {
        self = instrument.tunings().first!
    }
    
    func index(instrument: InstrumentSci) -> Int? {
        return instrument.tunings().index(of: self)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    static let guitarTunings = [
        TuningSci("standard", "e2 a2 d3 g3 b3 e4"),
        TuningSci("new_standard", "c2 g2 d3 a3 e4 g4"),
        TuningSci("russian", "d2 g2 b2 d3 g3 b3 d4"),
        TuningSci("drop_d", "d2 a2 d3 g3 b3 e4"),
        TuningSci("drop_c", "c2 g2 c3 f3 a3 d4"),
        TuningSci("drop_g", "g2 d2 g3 c4 e4 a4"),
        TuningSci("open_d", "d2 a2 d3 f#3 a3 d4"),
        TuningSci("open_c", "c2 g2 c3 g3 c4 e4"),
        TuningSci("open_g", "g2 g3 d3 g3 b3 d4"),
        TuningSci("lute", "e2 a2 d3 f#3 b3 e4"),
        TuningSci("irish", "d2 a2 d3 g3 a3 d4")
    ]
    
    static let celloTunings = [
        TuningSci("standard", "c2 g2 d3 a3"),
        TuningSci("alternative", "c2 g2 d3 g3")
    ]
    
    static let violinTunings = [
        TuningSci("standard", "g3 d4 a4 e5"),
        TuningSci("tenor", "g2 d3 a3 e4"),
        TuningSci("tenor_alter", "f2 c3 g3 d4")
    ]
    
    static let banjoTunings = [
        TuningSci("standard", "g4 d3 g3 b3 d4")
    ]
    
    static let balalaikaTunings = [
        TuningSci("standard_prima", "e4 e4 a4"),
        TuningSci("bass", "e2 a2 d3"),
        TuningSci("tenor", "a2 a2 e3"),
        TuningSci("alto", "e3 e3 a3"),
        TuningSci("secunda", "a3 a3 d4"),
        TuningSci("piccolo", "b4 e5 a5")
    ]
    
    static let ukuleleTunings = [
        TuningSci("standard", "g4 c4 e4 a4"),
        TuningSci("d_tuning", "a4 d4 f#4 b4")
    ]
    
    static let freemodeTunings = [
        TuningSci("octaves", "c2 c3 c4 c5 c6"),
        TuningSci("c_major", "c3 d3 e3 f3 g3 a3 b3"),
        TuningSci("c_minor", "c3 d3 e3 f3 g3 a3 b3")
    ]
}
