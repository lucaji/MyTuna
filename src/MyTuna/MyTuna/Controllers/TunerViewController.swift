
//
//  TunerViewController.swift
//  MyTuna
//
//  Copyright (c) 2018 lookaji. All rights reserved.
//

// MARK:- Imports

import UIKit
import AVFoundation
import SpriteKit
import AudioKit



// MARK:- TunerViewController

class TunerViewController: BaseViewController {
    
    typealias `Self` = TunerViewController

    // Parameter control properties
    enum sliderParameter {
        case volume
        case threshold
    }
    var currentSliderParameter : sliderParameter = .volume

    // Internals
    var tapping : Bool {
        didSet {
            if tapping {
                let granted = MTSignalPlayer.singleton.checkMicPermission(withPresentingViewController: self)
                if granted {
                    self.microphone?.activate()
                    oscilloscopeView.isPaused = false
                    self.waveformActivationToggleButton.image = UIImage(named:"waveformOnIcon")
                }
            } else {
                self.microphone?.inactivate()
                self.tubeScene?.cleanWave()
                oscilloscopeView.isPaused = true
                self.waveformActivationToggleButton.image = UIImage(named:"waveformOffIcon")

            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        tapping = false
        super.init(coder:aDecoder)
    }
    
    
    @IBOutlet weak var tuningNotesStackView: UIStackView!
    @IBOutlet weak var sliderButton: LJHelpableButton!
    @IBOutlet weak var parameterSlider: UISlider!
//    @IBOutlet weak var tuningsListButton: LJHelpableButton!

    // TUNERSCI Properties
    var tuner = TunerSci.sharedInstance
    let processing = Processing(pointCount: Settings.processingPointCount)
    var microphone: Microphone?
    @IBOutlet weak var oscilloscopeView: SKView!
    var tubeScene: TubeScene?

    
    @IBOutlet weak var panelView: UIView!
    
    // MARK: Properties
//    var tuner = TunerSci.sharedInstance

    @IBOutlet weak var gaugeView: WMGaugeView!
    @IBOutlet weak var pitchLabel: UILabel!
    
    @IBOutlet weak var gaugeActivationToggleButton: LJHelpableBarButtonItem!
    @IBOutlet weak var waveformActivationToggleButton: LJHelpableBarButtonItem!
    
    @IBOutlet weak var diapasonButton: LJHelpableButton!
    
    @IBOutlet weak var tuningTypeLabel: UILabel!
//    @IBOutlet weak var octavaAltaButton: LJHelpableButton!
    @IBOutlet weak var playStopTuneButton: LJHelpableButton!

    // MARK: UIViewController Lifecycle
    
    @objc func willResignActive(_ notification: Notification) {
        tapping = false
    }

    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: .mt_coredata_importedCsv, object: nil, queue: nil) { (note) in
            if let tuningImportLogString = note.userInfo?[LJK.NotificationKeys.coreDataImportedCsvObjectKey] as? String {
                self.showAlert(withTitle: "Import completed.", andMessage: tuningImportLogString)
            }
        }

        
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStart, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif playing.")
            self.diapasonButton.isSelected = true
        }
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStop, object: nil, queue: nil) { (note) in
            StuffLogger.print("oscillator notif stopping.")
            self.diapasonButton.isSelected = false
        }
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStart, object: nil, queue: nil) { (note) in
            StuffLogger.print("arpeggiator notif playing.")
            self.playStopTuneButton.setImage(UIImage(named:"PauseIcon"), for: .normal)
        }
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStop, object: nil, queue: nil) { (note) in
            StuffLogger.print("arpeggiator notif stopping.")
            self.playStopTuneButton.setImage(UIImage(named:"PlayIcon"), for: .normal)
        }
        NotificationCenter.default.addObserver(forName: .mt_referenceTuningHasChanged, object: nil, queue: nil) { (note) in
            let tuning = note.userInfo![LJK.NotificationKeys.referenceTuningHasChangedObjectKey] as! Tuning
            self.configure(withTuning: tuning)
        }
        NotificationCenter.default.addObserver(forName: .mt_coredata_shallUpdate, object: nil, queue: nil) { (note) in
            let tuning = MTSignalPlayer.singleton.currentTuning
            self.configure(withTuning: tuning)
        }
        NotificationCenter.default.addObserver(forName: .mt_tunerDidFail, object: nil, queue: nil) { (note) in
            //            StuffLogger.print("tuner did fail recogn.")
            if (self.pitchLabel.text != "") {
                self.pitchLabel.text = ""
//                self.gaugeView.value = 0.0
            }
        }
        NotificationCenter.default.addObserver(forName: .mt_tunerDidUpdate, object: nil, queue: nil) { (note) in
            let output = note.userInfo![LJK.NotificationKeys.referenceTuningHasChangedObjectKey] as! TunerOutput
                self.pitchLabel.text = output.notePitchAndOctaveString
//                self.gaugeView.value = Float(output.distance)
        }
        NotificationCenter.default.addObserver(forName: .mt_playTransposeDidChange, object: nil, queue: nil) { (note) in
//            self.octavaAltaButton.isSelected = MTSignalPlayer.singleton.transpose
        }
        NotificationCenter.default.addObserver(forName: .mt_tunerDidStart, object: nil, queue: nil) { (note) in
            self.gaugeActivationToggleButton.image = UIImage(named:"gaugeOnIcon")
        }
        

        NotificationCenter.default.addObserver(forName: .mt_tunerDidStop, object: nil, queue: nil) { (note) in
            self.pitchLabel.text = ""
            self.gaugeView.value = 0.0
            self.gaugeActivationToggleButton.image = UIImage(named:"gaugeOffIcon")
        }
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .mt_oscillatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_oscillatorDidStop, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStop, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_referenceTuningHasChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_tunerDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_tunerDidFail, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_tunerDidUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_tunerDidStop, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_playTransposeDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_coredata_shallUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_coredata_importedCsv, object: nil)
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate var volumeTitle = "Volume"
    fileprivate var thresholdTitle = "Threshold"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let splitVc = self.splitViewController {
            if splitVc.viewControllers.count > 1 {
                enablePanelHiddableOption = false
                self.navigationItem.leftBarButtonItems!.append(splitVc.displayModeButtonItem);
            } else  {
                // iphone
//                volumeTitle = "Vol"
//                thresholdTitle = "Mic"
                enablePanelHiddableOption = true
//                sliderButton.setTitle(volumeTitle, for: .normal)
            }
        }

        // Add block observation for notifications
        addObservers()
        setupTunerGauge(withGaugeView: self.gaugeView)

        // Tube Scene with Microphone
        microphone = Microphone(sampleRate: AKSettings.sampleRate, sampleCount: Settings.sampleCount)
        microphone?.delegate = self
        tuner.delegate = self
        tubeScene = TubeScene(size: oscilloscopeView.bounds.size)
        oscilloscopeView.presentScene(tubeScene)
        oscilloscopeView.ignoresSiblingOrder = true
        tubeScene?.customDelegate = self
        oscilloscopeView.isPaused = true

        pitchLabel.text = ""
        
        gaugeActivationToggleButton.configure(with: self) {
            MTSignalPlayer.singleton.toggleTuner()
        }
        
        waveformActivationToggleButton.configure(with: self) {
            let granted = MTSignalPlayer.singleton.checkMicPermission(withPresentingViewController: self)
            if granted {
                self.tapping = !self.tapping
            }
        }
        
        playStopTuneButton.configure(with: self) {
            MTSignalPlayer.singleton.togglePlucking()
        }
        
        sliderButton.configure(with: self) {
            let controller = UIAlertController(title: "Parameters", message: "Choose a slider parameter", preferredStyle: UIAlertController.Style.actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
                
            })
            controller.addAction(cancelAction)
            
            let volumeAction = UIAlertAction(title: "Volume", style: .default) { (_) -> Void in
                self.currentSliderParameter = .volume
                self.sliderButton.setTitle(self.volumeTitle, for: .normal)
                self.updateLogSlider(MTSignalPlayer.singleton.theVolume)
//                self.parameterSlider.value = Float(MTSignalPlayer.singleton.theMixer!.volume)
            }
            controller.addAction(volumeAction)
            
            let sensAction = UIAlertAction(title: "Tuner Threshold", style: .default) { (_) -> Void in
                self.currentSliderParameter = .threshold
                self.sliderButton.setTitle(self.thresholdTitle, for: .normal)
                self.parameterSlider.value = Float(MTSignalPlayer.singleton.threshold)
            }
            controller.addAction(sensAction)
            
            //        let tuningListAction = UIAlertAction(title: "Tunings List", style: .default) { (_) -> Void in
            //        }
            //        controller.addAction(tuningListAction)
            
            if let popoverController = controller.popoverPresentationController {
                popoverController.sourceRect = self.sliderButton.bounds
                popoverController.sourceView = self.sliderButton
            }
            self.present(controller, animated: true, completion: nil)
        }
        
//        tuningsListButton.configure(with: self) {
////            if UIDevice.current.userInterfaceIdiom == .pad {
//                self.performSegue(withIdentifier: "segueToTuningDetail", sender: self)
////            } else {
////
////            }
//        }

//        octavaAltaButton.configure(with: self) {
//            MTSignalPlayer.singleton.transpose = !MTSignalPlayer.singleton.transpose
//        }
        
        diapasonButton.configure(with: self) {
            MTSignalPlayer.singleton.toggleSignal()
        }
    }

    func setupTunerGauge(withGaugeView gaugeView : WMGaugeView) {
        gaugeView.style = WMGaugeViewStyleFlatThin()
        
        gaugeView.maxValue = 50.0
        gaugeView.minValue = -50.0
        // gaugeView.needleWidth = 0.01
        // gaugeView.needleHeight = 0.4
        gaugeView.scaleDivisions = 10
        gaugeView.scaleEndAngle = 270
        gaugeView.scaleStartAngle = 90
        gaugeView.scaleSubdivisions = 5
        gaugeView.showScaleShadow = false
        // gaugeView.needleScrewRadius = 0.05
        gaugeView.scaleDivisionsLength = 0.05
        gaugeView.scaleDivisionsWidth = 0.007
        gaugeView.scaleSubdivisionsLength = 0.02
        gaugeView.scaleSubdivisionsWidth = 0.002
        gaugeView.backgroundColor = UIColor.clear
        //        gaugeView.needleStyle = WMGaugeViewNeedleStyleFlatThin
        //        gaugeView.needleScrewStyle = WMGaugeViewNeedleScrewStylePlain
        //        gaugeView.innerBackgroundStyle = WMGaugeViewInnerBackgroundStyleFlat
        //        gaugeView.scalesubdivisionsaligment = WMGaugeViewSubdivisionsAlignmentCenter
        gaugeView.scaleFont = UIFont.systemFont(ofSize: 0.05, weight: UIFont.Weight.ultraLight)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        configure(withTuning: MTSignalPlayer.singleton.currentTuning)
        
        switch (self.currentSliderParameter) {
        case .threshold:
            self.parameterSlider.value = Float(MTSignalPlayer.singleton.threshold)
        case .volume:
            self.updateLogSlider(MTSignalPlayer.singleton.theVolume)
        }
        
//        octavaAltaButton.isSelected = MTSignalPlayer.singleton.transpose
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        tapping = false
    }
    
    deinit {
        removeObservers()
    }

    // View Controller Presentation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        gaugeView.invalidateNeedle()
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "popoverSearch" {
//            segue.destination.popoverPresentationController?.delegate = self
//        }
    }


    // MARK: Actions
    var enablePanelHiddableOption = true
    @IBAction func settingsButtonAction(_ sender: UIBarButtonItem) {
        let controller = UIAlertController(title: "mytuna Settings", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
            
        })
        controller.addAction(cancelAction)
        
//        let helpModeActive = LJHelpablePopoverViewController.singleton().usingHelpMode
//
//        let helpModeAction = UIAlertAction(title: helpModeActive ? "Turn Help off" : "Turn Help on", style: .default) { (_) -> Void in
//            LJHelpablePopoverViewController.singleton().usingHelpMode = !helpModeActive
//        }
//        controller.addAction(helpModeAction)
        
        // 8VA TRASPOSE
        let otva = MTSignalPlayer.singleton.transpose
        let transposeAction = UIAlertAction(title: otva ? "Disable 8va transpose" : "Enable 8va transpose", style: .default) { (_) -> Void in
            MTSignalPlayer.singleton.transpose = !otva
        }
        controller.addAction(transposeAction)

        if UIDevice.current.userInterfaceIdiom == .phone {
            // SPEAKERPHONE
            let isSpeakerOverridden = MTSignalPlayer.singleton.isSpeakerOverridden
            let speakerphoneAction = UIAlertAction(title: isSpeakerOverridden ? "Disable Speakerphone" : "Activate Speakerphone", style: .default) { (_) -> Void in
                MTSignalPlayer.singleton.isSpeakerOverridden = !isSpeakerOverridden
            }
            controller.addAction(speakerphoneAction)
        }
        if enablePanelHiddableOption {
            let panelIsHidden = panelView.isHidden
            let togglePanelVisibilityAction = UIAlertAction(title: panelIsHidden ? "Show Main Panel" : "Hide Main Panel", style: .default) { (_) -> Void in
                UIView.animate(withDuration: 0.5, animations: {
                    self.panelView.isHidden = !panelIsHidden
                })
            }
            controller.addAction(togglePanelVisibilityAction)
        }
        let importAction = UIAlertAction(title: "Import Tunings...", style: .default) { (_) -> Void in
            self.displayDocumentPicker()
        }
        controller.addAction(importAction)

        let exportAction = UIAlertAction(title: "Export Tunings...", style: .default) { (_) -> Void in
            if let url = CoreDataStack.singleton.exportAllTunings(withPresenterVc: self, withBarButton: sender) {
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
                vc.excludedActivityTypes = [
                    UIActivity.ActivityType.assignToContact,
                    UIActivity.ActivityType.saveToCameraRoll,
                    UIActivity.ActivityType.postToFlickr,
                    UIActivity.ActivityType.postToVimeo,
                    UIActivity.ActivityType.postToTencentWeibo,
                    UIActivity.ActivityType.postToTwitter,
                    UIActivity.ActivityType.postToFacebook,
                    UIActivity.ActivityType.openInIBooks
                ]
                
                if let pc = vc.popoverPresentationController {
                    pc.delegate = self
                    pc.barButtonItem = sender
                }
                self.present(vc, animated: true, completion: nil)

            }
        }
        controller.addAction(exportAction)

        let restoreAction = UIAlertAction(title: "Restore default tunings...", style: .default) { (_) -> Void in
            let restorecontroller = UIAlertController(title: "Default Tunings", message: "This action will restore all the original tunings.", preferredStyle: UIAlertController.Style.alert)
            let restorecancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
                
            })
            restorecontroller.addAction(restorecancelAction)
            
            let restorerestoreAction = UIAlertAction(title: "Restore", style: .destructive) { (_) -> Void in
                let restored = CoreDataStack.singleton.MTImportDefaultTunings()
                self.showAlert(withTitle: "Tunings Restored", andMessage: "\(restored) tunings restored.")
            }
            restorecontroller.addAction(restorerestoreAction)
            self.present(restorecontroller, animated: true, completion: nil)
        }
        controller.addAction(restoreAction)

        
        let aboutAction = UIAlertAction(title: "About mytuna...", style: .default) { (_) -> Void in
            self.performSegue(withIdentifier: "segueToAbout", sender: self)
        }
        controller.addAction(aboutAction)
        
        if let popoverController = controller.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        self.present(controller, animated: true, completion: nil)

    }
    
    @IBAction func parameterSliderAction(_ sender: UISlider) {
        switch (currentSliderParameter) {
        case .volume:
            let valog = readLogSlider(Double(sender.value))
            MTSignalPlayer.singleton.theVolume = valog
        case .threshold:
            MTSignalPlayer.singleton.threshold = Double(sender.value)
        }
    }
    
    func updateLogSlider(_ theValue:Double) {
//        let valog = readLogSlider(theValue)
        self.parameterSlider.value = Float(theValue)
    }

    func readLogSlider(_ theValue:Double) -> Double {
        return theValue
//        var valog = log(exp(1.0) / exp(theValue))
//        if (valog > 1.0) {
//            valog = 1.0
//            StuffLogger.print(valog)
//        }
//        return valog
    }
    
    @IBAction func parameterSlideActionDidEnd(_ sender: UISlider) {
        StuffLogger.print("saving defaults")
        let defaults = UserDefaults.standard
        switch (currentSliderParameter) {
        case .volume:
            let valog = readLogSlider(Double(sender.value))
            MTSignalPlayer.singleton.theVolume = valog
            defaults.set(valog, forKey: LJK.AppDefaultsKeys.volumeKey)
        case .threshold:
            let threshold = Double(sender.value)
            MTSignalPlayer.singleton.threshold = threshold
            defaults.set(threshold, forKey: LJK.AppDefaultsKeys.thresholdKey)
        }
        defaults.synchronize()
    }

    
    // Double tap to toggle on-off
    @IBAction func tuningSegmentDoubleTapAction(_ sender: UITapGestureRecognizer) {
        MTSignalPlayer.singleton.stopGenerators()
    }
    
    
    
    // MARK: Data source
    
    @objc func pressButton(_ sender: UIButton) { //<- needs `@objc`
        let title = sender.title(for: .normal)
        
        let freq = MTSignalPlayer.singleton.prepareFor(noteName: title!)
        processing.setTargetFrequency(freq)

        if sender.isSelected {
            for case let button as UIButton in self.tuningNotesStackView.arrangedSubviews {
                if button == sender {
                    button.isSelected = false
                } else {
                    button.isSelected = true
                }
            }
            MTSignalPlayer.singleton.playOscillator()

        } else {
            sender.isSelected = true
            MTSignalPlayer.singleton.stopOscillator()
        }
    }
    
    @objc func clearButton(_ sender: UIButton){ //<- needs `@objc`
        let title = sender.title(for: .normal)
        StuffLogger.print(title)
        sender.isSelected = true
        MTSignalPlayer.singleton.stopOscillator()
    }


    func configure(withTuning tuning : Tuning) {
        //        self.title = tuning.tuningName
        self.tuningTypeLabel.text = "\(tuning.tuningName!) - \(tuning.tuningInstrument!.instrumentName!) - \(tuning.tuningType!.tuningTypeName!)"

        let notesString = tuning.tuningNotes
        let notes = notesString!.components(separatedBy: "-")
        let numberOfButtons = tuningNotesStackView.arrangedSubviews.count
        if (notes.count > numberOfButtons) {
            let addo = notes.count - numberOfButtons
            for _ in 1...addo {
                let niuBettone = UIButton(type: .system)
                niuBettone.isSelected = true
                niuBettone.addTarget(self, action: #selector(self.pressButton(_:)), for: .touchDown)
//                niuBettone.addTarget(self, action: #selector(self.pressButton(_:)), for: .touchUpInside)
//                niuBettone.addTarget(self, action: #selector(self.clearButton(_:)), for: .touchDragExit)
//                niuBettone.addTarget(self, action: #selector(self.clearButton(_:)), for: .touchDragOutside)
//                niuBettone.addTarget(self, action: #selector(self.clearButton(_:)), for: .touchUpOutside)
//                niuBettone.addTarget(self, action: #selector(self.clearButton(_:)), for: .touchCancel)
                tuningNotesStackView.addArrangedSubview(niuBettone)
            }
        } else if (notes.count < numberOfButtons) {
            let subo = numberOfButtons - notes.count
            for _ in 1...subo {
                let deletingButton = tuningNotesStackView.arrangedSubviews.first
                tuningNotesStackView.removeArrangedSubview(deletingButton!)
                deletingButton?.removeFromSuperview()
            }
        }
        
        var i = 0
        for case let button as UIButton in self.tuningNotesStackView.arrangedSubviews {
            let title = notes[i]
            button.setTitle(title, for: .normal)
            i += 1
        }

    }

    
}

// MARK: SciTuner delegate

extension TunerViewController: TunerSciDelegate {
    func didSettingsUpdate() {
//        switch tuner.filter {
//        case .on: processing.enableFilter()
//        case .off: processing.disableFilter()
//        }
    }
    
    func didFrequencyChange() {
        //panel?.targetFrequency?.text = String(format: "%.2f %@", tuner.targetFrequency(), "Hz".localized())
    }
    
    func didStatusChange() {
        if tuner.isActive {
            microphone?.activate()
        } else {
            microphone?.inactivate()
        }
    }
}


// MARK: SciTunerMicrophone Delegate

extension TunerViewController: MicrophoneDelegate {
    func microphone(_ microphone: Microphone?, didReceive data: [Double]?) {
//        if !tapping {
//            return
//        }

        if tuner.isPaused {
            return
        }

        if let tf = tuner.targetFrequency() {
            processing.setTargetFrequency(tf)
        }

        guard let micro = microphone else {
            return
        }

        var wavePoints = [Double](repeating: 0, count: Int(processing.pointCount-1))
        let band = tuner.band()
        processing.setBand(fmin: band.fmin, fmax: band.fmax)
        
        processing.push(&micro.sample)
        processing.savePreview(&micro.preview)
        
        processing.recalculate()
        
        processing.buildSmoothStandingWave2(&wavePoints, length: wavePoints.count)
        
        tuner.frequency = processing.getFrequency()
        tuner.updateTargetFrequency()
        
        tubeScene?.draw(wave: wavePoints)

        self.gaugeView.value = Float(tuner.noteDeviation())

//        if (tunerActivated && !useTuningFork) {
//            let frequency = processing.getFrequency()
//            var norm = frequency
//            if (frequency > 30) {
//                while norm > MTTuningUtils.frequencies[MTTuningUtils.frequencies.count - 1] {
//                    norm = norm / 2.0
//                }
//                while norm < MTTuningUtils.frequencies[0] {
//                    norm = norm * 2.0
//                }
//
//                var i = -1
//                var min = Double.infinity
//                for n in 0...MTTuningUtils.frequencies.count-1 {
//                    let diff = MTTuningUtils.frequencies[n] - norm
//                    if abs(diff) < abs(min) {
//                        min = diff
//                        i = n
//                    }
//                }
//
//                let octave = i / 12
//                let distance = frequency - MTTuningUtils.frequencies[i]
//                let pitch = String(format: "%@", MTTuningUtils.sharps[i % MTTuningUtils.sharps.count], MTTuningUtils.flats[i % MTTuningUtils.flats.count])
//                let noteName = pitch + "\(octave)"
//                //        DispatchQueue.main.async {
//                self.gaugeView.value = Float(tuner.noteDeviation())
//                //        self.gaugeView.value = Float(tuner.noteDeviation())
//                self.pitchLabel.text = noteName
//                //        }
//            } else {
//                self.gaugeView.value = 0.0
//                self.pitchLabel.text = nil
//            }
//            tuner.frequency = frequency
//            tuner.updateTargetFrequency()
//        }

    }
    
    
}

// MARK: LJHelpablePopoverViewControllerDelegate

//extension TunerViewController : LJHelpablePopoverViewControllerDelegate {
//    func lj_HelpablePopoverAboutButtonAction() {
//        performSegue(withIdentifier: "segueToAbout", sender: self)
//    }
//}


// MARK: Scene Delegate

extension TunerViewController: TubeSceneDelegate {
//    func getNotePosition() -> CGFloat {
//        return CGFloat(tuner.notePosition())
//    }
    
    func getPulsation() -> CGFloat {
        return CGFloat(processing.pulsation())
    }
}



// MARK: UIDocumentPickerDelegate

extension TunerViewController : UIDocumentPickerDelegate {
    // MARK: Document picker
    func displayDocumentPicker() {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text", "public.text"], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        StuffLogger.print("import cancelled.")
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            StuffLogger.print("commencing import \(url.path).")
            let imported = CoreDataStack.singleton.importCsv(fromUrl: url)
            StuffLogger.print("imported: \(imported).")
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            
        }
    }
}
