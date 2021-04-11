
//
//  TunerViewController.swift
//  Partita
//
//  Copyright (c) 2015 Comyar Zaheri. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//


// MARK:- Imports

import UIKit
import TuningFork
import BFPaperButton
import PermissionScope
import PodsLicenseReader
import GaugeKit
import AudioKit

// MARK:- MainViewController

class Main2ViewController: UIViewController, TunerDelegate, UIPopoverPresentationControllerDelegate {

    // MARK: Properties
    
    @IBOutlet weak var listenBarButton: UIBarButtonItem!
    @IBOutlet weak var leftTunerView: Gauge!
    @IBOutlet weak var midTunerView: Gauge!
    @IBOutlet weak var rightTunerView: Gauge!


    @IBOutlet weak var pitchLabel: UILabel!

    fileprivate var tuner: Tuner?
    fileprivate var infoButton: BFPaperButton?
    fileprivate var infoViewController: InfoViewController?

    @IBOutlet weak var refNotesSegmentedControl: UISegmentedControl!

    fileprivate var running = false
    fileprivate let permissions = PermissionScope()

    var oscillator = AKOscillator()

    func freqForIndex(_ index:Int) -> Double {
        var freq = 440.0
        switch index {
        case 0: // C
            freq = 261.63
            break

        case 1: // D
            freq = 293.66
            break

        case 2: // E
            freq = 329.63
            break

        case 3: // F
            freq = 349.23
            break

        case 4: // G
            freq = 392.00
            break

        case 5: // A
            freq = 440.0
            break

        case 6: // B
            freq = 493.88
            break
            
        default: break
        }
        return freq
    }

    @IBAction func refNoteSelectedChanged(_ sender: UISegmentedControl) {
        let freq = freqForIndex(sender.selectedSegmentIndex)

        oscillator.amplitude = 0.6
        oscillator.frequency = freq

        if !oscillator.isPlaying {
            oscillator.start()
        }
    }

    @IBAction func toneButtonAction(_ sender: UIBarButtonItem) {
        let freq = freqForIndex(refNotesSegmentedControl.selectedSegmentIndex)

        if oscillator.isPlaying {
            oscillator.stop()
        } else {
            oscillator.amplitude = 0.6
            oscillator.frequency = freq
            oscillator.start()
//            sender.setTitle("Stop Sine Wave at \(Int(oscillator.frequency))Hz", forState: .Normal)
        }

    }
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AudioKit.output = AKMixer(oscillator)
        AudioKit.start()

        permissions.addPermission(MicrophonePermission(), message: "MyTuna needs the microphone to listen...")
        permissions.closeButtonTextColor = UIColor.actionButtonColor()
        permissions.authorizedButtonColor = UIColor.authorizedColor()
        permissions.unauthorizedButtonColor = UIColor.unauthorizedColor()
        permissions.headerLabel.textColor = UIColor.textColor()
        permissions.bodyLabel.textColor = UIColor.textColor()
        permissions.permissionLabelColor = UIColor.textColor()

        tuner = Tuner()
        tuner?.delegate = self

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(stopTuner), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        notificationCenter.addObserver(self, selector: #selector(startTuner), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.popoverPresentationController?.delegate = self
    }

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    // MARK: Tuner Controls
    
    func startTuner() {
        print("startTuner")
        if !running {
            running = true
            tuner?.start()
//            tunerView?.actionButton.setTitle("Stop", for: .normal)
//            tunerView?.actionButton.backgroundColor = UIColor.partitaDarkBlueColor()
        }
    }
    
    func stopTuner() {
        print("stopTuner")
        if running {
            running = false
            tuner?.stop()
            leftTunerView.rate = 0.0
            midTunerView.rate = 0.0
            rightTunerView.rate = 0.0
            pitchLabel.text = "--"
//            tunerView?.actionButton.setTitle("Start", for: .normal)
//            tunerView?.actionButton.backgroundColor = UIColor.actionButtonColor()
        }
    }
    
    // MARK: TunerDelegate
    
    func tunerDidUpdate(_ tuner: Tuner, output: TunerOutput) {
        if output.amplitude < 0.01 {
            leftTunerView.rate = 0.0
            midTunerView.rate = 0.0
            rightTunerView.rate = 0.0

            pitchLabel.text = "--"
        } else {
            pitchLabel.text = output.pitch + "\(output.octave)"
            let rate = CGFloat(Float(output.distance))

            leftTunerView.rate = rate
            midTunerView.rate = rate
            rightTunerView.rate = rate

        }
    }
    
    // MARK: UIButton
    
    @IBAction func listenButtonAction(_ sender: UIBarButtonItem) {
            if running {
                stopTuner()
            } else {
                if permissions.statusMicrophone() == .authorized {
                    self.startTuner()
                } else {
                    permissions.show({ (finished, results) -> Void in
                        let result = results.filter({ $0.type == .microphone })[0]
                        if result.status != .authorized {
                            self.showMicrophoneAccessAlert()
                        }
                    }, cancelled: { (results) -> Void in
                            self.showMicrophoneAccessAlert()
                    })
                }
            }
//        } else if button == infoButton {
//            infoViewController = InfoViewController()
//            infoViewController?.transitioningDelegate = self
//            infoViewController?.modalPresentationStyle = .custom
//            self.present(infoViewController!, animated: true, completion: nil)
//        }
    }
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    // MARK: Private
    
    fileprivate func showMicrophoneAccessAlert() {
        let alert = UIAlertController(title: "Microphone Access", message: "Partita requires access to your microphone; please enable access in your device's settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
