//
//  ViewController.swift
//  MyTunaStrumTest
//
//  Created by Luca Cipressi on 16/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit
import AudioKit


class ViewController: UIViewController {

    enum PlayMode {
        case signalgen
        case plucked
        case droning
        case grooving
    }
    

    fileprivate var generator:AKOperationGenerator?
    fileprivate var genBooster: AKBooster?
    fileprivate var theMixer : AKMixer?

    fileprivate var baseMetronome = 0.0
    var thePlayMode = PlayMode.grooving

    override func viewDidLoad() {
        super.viewDidLoad()
        // AudioKit Settings
        AKSettings.fixTruncatedRecordings = true
        #if DEBUG
            AKSettings.enableLogging = true
        #else
            AKSettings.enableLogging = false
        #endif
//        do {
//            try AKSettings.setSession(category: .playAndRecord)
//        } catch let error as NSError {
//            print(error)
//        }
        
        generator = AKOperationGenerator() { parameters in
            var instruments:AKOperation?
            for i in 0...6 {
                let f = parameters[i]// * (self.transpose ? 2.0 : 1.0)
                let d = parameters[i + 7]
                
                switch thePlayMode {
                case .droning:
                    baseMetronome = 0.0
                case .plucked:
                    baseMetronome = -1.0
                case .grooving:
                    baseMetronome = 1.0
                default:
                    baseMetronome = 0.0
                }

                let metro = AKOperation.metronome(frequency:d * baseMetronome)

                let theInstrument = AKOperation.pluckedString(trigger: metro, frequency: f, amplitude:0.15)
                if let _ = instruments {
                    instruments = instruments! + theInstrument
                } else {
                    instruments = theInstrument
                }
            }
            instruments = instruments! * 0.80
            let reverb = instruments!.reverberateWithCostello(feedback: 0.6, cutoffFrequency: 20000).toMono()
            return reverb
        }
        genBooster = AKBooster(generator)
        genBooster!.rampTime = 0.2
        genBooster!.gain = 0.0

        theMixer = AKMixer(genBooster)
        theMixer?.volume = 0.7
        AudioKit.output = theMixer
        initializeStringsWithStandardTuning()
    }
    
    // Arpeggiator parms
    let euroTones =  [1.0,9.0/8.0,5.0/4.0,4.0/3.0,3.0/2.0,5.0/3.0,15.0/8.0,2.0/1.0]
    let ancientGreekTones = [1.0, 32.0/31.0, 16.0/15.0, 4.0/3.0, 3.0/2.0, 48.0/31.0, 8.0/5.0,2.0/1.0]
    func ratioForNoteNamed(_ noteName:String, atPosition pos:Int) -> Double {
        let prefixo = noteName.prefix(1)
        var n = 0
        switch (prefixo) {
        case "C": n = 0
        case "D": n = 1
        case "E": n = 2
        case "F": n = 3
        case "G": n = 4
        case "A": n = 5
        case "B": n = 6
        default: n = 1
        }
        return euroTones[(n + pos) % 7]
    }


    func initializeStringsWithStandardTuning() {
        let defaultTuning = ["E2", "A2", "D3", "G3", "B3", "E4"]
        switch thePlayMode {
        case .droning:
            baseMetronome = 0.0
        case .plucked:
            baseMetronome = -1.0
        case .grooving:
            baseMetronome = 1.0
        default: break
        }
        if let theGenerator = generator {
            for (i, notename) in defaultTuning.enumerated() {
                let note = notename.toSinglePitchedNote()
                let f = note.frequency
                let theBeat = ratioForNoteNamed(note.noteNameSharp, atPosition:i) * baseMetronome
                theGenerator.parameters[i] = f
                theGenerator.parameters[i + 7] = theBeat
            }
        }
    }

    fileprivate var isPlaying = false
    @IBOutlet weak var toggleButton: UIButton!
    @IBAction func toggleButtonAction(_ sender: UIButton) {
        if isPlaying {
            sender.setTitle("Play", for: .normal)
            stop()
        } else {
            play()
            sender.setTitle("Stop", for: .normal)
        }
    }
    func play() {
        genBooster!.gain = 1.0
        if let theGenerator = generator {
            theGenerator.start()
            print("started gen.")
            isPlaying = true
        }
    }
    
    func stop() {
        genBooster!.gain = 0.0
        if let theGenerator = generator {
            theGenerator.stop()
            print("stopped gen.")
            isPlaying = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("starting ak...")
        AudioKit.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("stopping ak...")
        AudioKit.stop()

    }

    
}

