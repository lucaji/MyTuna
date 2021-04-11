//
//  Note.swift
//  MyTuna
//
//  Created by Luca Cipressi on 20170411.
//  Copyright © 2017 Lookaji. All rights reserved.
//

import Foundation

struct MTPitchedNote: Comparable, CustomStringConvertible{
    typealias `Self` = MTPitchedNote
    
    public static let flats = ["C", "D♭","D","E♭","E","F","G♭","G","A♭","A","B♭","B"]
    public static let sharps = ["C", "C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
    public static let frequencies: [Double] = [
        16.35, 17.32, 18.35, 19.45, 20.60, 21.83, 23.12, 24.50, 25.96, 27.50, 29.14, 30.87, // 0
        32.70, 34.65, 36.71, 38.89, 41.20, 43.65, 46.25, 49.00, 51.91, 55.00, 58.27, 61.74, // 1
        65.41, 69.30, 73.42, 77.78, 82.41, 87.31, 92.50, 98.00, 103.8, 110.0, 116.5, 123.5, // 2
        130.8, 138.6, 146.8, 155.6, 164.8, 174.6, 185.0, 196.0, 207.7, 220.0, 233.1, 246.9, // 3
        261.6, 277.2, 293.7, 311.1, 329.6, 349.2, 370.0, 392.0, 415.3, 440.0, 466.2, 493.9, // 4
        523.3, 554.4, 587.3, 622.3, 659.3, 698.5, 740.0, 784.0, 830.6, 880.0, 932.3, 987.8, // 5
        1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976,             // 6
        2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951,             // 7
        4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902              // 8
    ]
    
    // MARK: Pitched Output
    
    static func newOutput(_ frequency: Double, _ amplitude: Double) -> TunerOutput {
        let output = TunerOutput()
        
        var norm = frequency
        while norm > frequencies[frequencies.count - 1] {
            norm = norm / 2.0
        }
        while norm < frequencies[0] {
            norm = norm * 2.0
        }
        
        var i = -1
        var min = Double.infinity
        for n in 0...frequencies.count-1 {
            let diff = frequencies[n] - norm
            if abs(diff) < abs(min) {
                min = diff
                i = n
            }
        }
        
        output.octave = i / 12
        output.frequency = frequency
        output.amplitude = amplitude
        //        output.distance = (frequency - MTTuningUtils.frequencies[i])
        
        let f1 = frequency
        let f2 = frequencies[i]
        let distanceInCents = 1200 * log(f2 / f1)
        output.distance = distanceInCents
        output.pitch = String(format: "%@", sharps[i % sharps.count], flats[i % flats.count])
        
        return output
    }


    static func noteNameByName(_ noteName :String) -> String {
        let offset = noteName.count == 3 ? 2 : 1
        return String(noteName.prefix(offset))
    }
    
    static func noteOctaveByName(_ noteName:String) -> Int {
        var octave = -1
        for i in 0...8 {
            if noteName.hasSuffix(String(i)) { octave = i }
        }
        return octave
    }
    
    fileprivate static func noteIndexInFlats(_ noteName:String) -> Int {
        var semitone = -1
        for (i, n) in flats.enumerated() {
            if noteName.hasPrefix(n) { semitone = i }
        }
        return semitone
    }
    
    
    fileprivate static func noteIndexInSharps(_ noteName:String) -> Int {
        var semitone = -1
        for (i, n) in sharps.enumerated() {
            if noteName.hasPrefix(n) { semitone = i }
        }
        return semitone
    }

    static func noteFrequencyByName(_ noteName:String, playingTranspose traspo:Int) -> Double {
        let octave = noteOctaveByName(noteName)
        let f = 0 //indexForNoteName(noteName)
        let index = f + (12 * (octave + traspo))
        return frequencies[index]
    }

    
    var number: Int = 0
    var frequency: Double { return MTPitchedNote.frequencies[number] }
    
    var octave: Int { return number / 12 }
    var semitone: Int { return number % 12 }
    var noteNameSharp: String { return MTPitchedNote.sharps[semitone] }
    var string: String {
        get { return MTPitchedNote.sharps[semitone] + String(octave) }
    }
    
    var description: String { return string }

    init(number: Int) {
        self.number = number
    }
    
    
    init(withOctave octave: Int, andSemitone semitone: Int) {
        number = 12 * octave + semitone
    }
    
    init?(withMidiNoteName name: String) {
        let uppercased = name.uppercased().trimmingCharacters(in: .whitespaces)
        var semitone = 0
        var octave = 0
        var success = false
        
        for (i, n) in MTPitchedNote.sharps.enumerated() {
            if uppercased.hasPrefix(n) {
                success = true
                semitone = i
            }
        }
        if !success { return nil }
        
        success = false
        for i in 0...8 {
            if uppercased.hasSuffix(String(i)) {
                success = true
                octave = i
            }
        }
        if !success { return nil }
        number = 12 * octave + semitone
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.number <= rhs.number
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.number == rhs.number
    }
    
    static func + (lhs: Self, rhs: Int) -> MTPitchedNote {
        return MTPitchedNote(number: lhs.number + rhs)
    }
}


// MARK:- TunerOutput

/**
 Contains information decoded by a Tuner, such as frequency, octave, pitch, etc.
 */
@objc public class TunerOutput: NSObject {
    
    /**
     The octave of the interpreted pitch.
     */
    public fileprivate(set) var octave: Int = 0
    
    
    public var notePitchAndOctaveString : String {
        get {
            return "\(pitch)\(octave)"
        }
    }
    
    /**
     The interpreted pitch of the microphone audio.
     */
    public fileprivate(set) var pitch: String = ""
    
    /**
     The difference between the frequency of the interpreted pitch and the actual
     frequency of the microphone audio.
     
     For example if the microphone audio has a frequency of 432Hz, the pitch will
     be interpreted as A4 (440Hz), thus making the distance -8Hz.
     */
    public fileprivate(set) var distance: Double = 0.0
    
    /**
     The amplitude of the microphone audio.
     */
    public fileprivate(set) var amplitude: Double = 0.0
    
    /**
     The frequency of the microphone audio.
     */
    public fileprivate(set) var frequency: Double = 0.0
    
    fileprivate override init() {}
}


// MARK: String extension

extension String {
    func toSinglePitchedNote() -> MTPitchedNote? {
        return MTPitchedNote(withMidiNoteName: self)
    }
    
    func toPitchedNotes() -> [MTPitchedNote] {
        var foundNotes = [MTPitchedNote]()
        let notes = self.components(separatedBy: "-")
        for note in notes {
            let nuNote = note.toSinglePitchedNote()
            if let theNewNote = nuNote {
                foundNotes.append(theNewNote)
            }
        }
        return foundNotes
    }
}

