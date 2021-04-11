//
//  ViewController.swift
//  Example
//
//  Created by gary on 17/05/2016.
//  Copyright © 2016 Gary Newby. All rights reserved.
//

import UIKit
import AVFoundation

class KeyboardViewController: UIViewController, GLNPianoViewDelegate {

    @IBOutlet weak var octavaButton: UIBarButtonItem!
    //    @IBOutlet weak var fascia: UIView!
    @IBOutlet weak var keyboard: GLNPianoView!

    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let layer = CAGradientLayer()
//        layer.frame = fascia.bounds
//        layer.colors = [UIColor.black.cgColor, UIColor.darkGray.cgColor, UIColor.black.cgColor]
//        layer.startPoint = CGPoint(x: 0.0, y: 0.80)
//        layer.endPoint = CGPoint(x: 0.0, y: 1.0)
//        fascia.layer.insertSublayer(layer, at: 0)

        keyboard.delegate = self
//        keyNumberStepper.value = Double(keyboard.numberOfKeys)
//        keyNumberLabel.text = String(keyNumberStepper.value)
//        octaveLabel.text = String(octaveStepper.value)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    func updateUI() {
        octavaButton.title = String(keyboard.octave)
    }

    func pianoKeyDown(_ keyNumber: UInt8) {
        StuffLogger.print(keyNumber)
//        audioEngine.sampler.startNote((keyboard.octave + keyNumber), withVelocity: 64, onChannel: 0)
    }

    func pianoKeyUp(_ keyNumber: UInt8) {
        StuffLogger.print(keyNumber)
//        audioEngine.sampler.stopNote((keyboard.octave + keyNumber), onChannel: 0)
    }

    @IBAction func showNotes(_: Any) {
        keyboard.toggleShowNotes()
    }
    @IBAction func ottvaButtonAction(_ sender: UIBarButtonItem) {
        keyboard.octave += 1
        updateUI()
    }
    
    @IBAction func ottvbButtonAction(_ sender: UIBarButtonItem) {
        keyboard.octave -= 1
        updateUI()
    }
    @IBAction func keyNumberStepperTapped(_ sender: UIStepper) {
        keyboard.numberOfKeys = Int(sender.value)
//        keyNumberLabel.text = String(keyNumberStepper.value)
    }

}

