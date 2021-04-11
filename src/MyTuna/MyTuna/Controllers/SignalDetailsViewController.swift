//
//  SignalDetailsViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

class SignalDetailsViewController: UIViewController {

    
    @IBOutlet weak var signalWaveformSegmentedControl: UISegmentedControl!
    @IBOutlet weak var signalFrequencyTextField: UITextField!
    @IBOutlet weak var playToggleButton: UIButton!
    @IBOutlet weak var signalFrequencySlider: UISlider!
    
    @IBAction func signalWaveformSegmentedControlAction(_ sender: UISegmentedControl) {
        let waveFormType = WaveForms(rawValue:sender.selectedSegmentIndex)
        MTSignalPlayer.singleton.prepareFor(waveform: waveFormType!)
    }
    
    @IBAction func frequencySliderChanged(_ sender: UISlider) {
        let freq = pow(10, sender.value)
        MTSignalPlayer.singleton.theFrequency = Double(freq)
        // LJSignalgenerator.singleton().prepareForSignalWithFreque
    }
    
    @IBAction func playToggleButtonAction(_ sender: Any) {
        MTSignalPlayer.singleton.toggleSignal()
    }
    
    override func viewDidLoad() {
        // Add block observation for notifications
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStart, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif playing.")
            self.playToggleButton.isSelected = true
        }
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStop, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif stopping.")
            self.playToggleButton.isSelected = false
        }
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidUpdateFrequency, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif playing.")
            self.signalFrequencyTextField.text = MTSignalPlayer.singleton.oscillatorFrequencyText()
        }
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidUpdateWaveform, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif playing.")
            self.signalFrequencyTextField.text = MTSignalPlayer.singleton.oscillatorFrequencyText()
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        MTSignalPlayer.singleton.stopGenerators()
        updateUI()
    }
    
    func updateUI() {
        signalFrequencySlider.value = log10f(Float(MTSignalPlayer.singleton.theFrequency))
        signalFrequencyTextField.text = MTSignalPlayer.singleton.oscillatorFrequencyText()
        signalWaveformSegmentedControl.selectedSegmentIndex = MTSignalPlayer.singleton.theWaveForm.rawValue

    }


}
