//
//  MTSignalPlayer.swift
//  MyTuna
//
//  Created by Luca Cipressi on 25/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI
import Schedule

struct LJK {
    struct NotificationKeys {
        static let oscillatorDidUpdateFrequency = "org.themilletgrainfromouterspace.MyTuna.oscillatordidChangeFrequency"
        static let oscillatorDidUpdateWaveform = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidUpdateWaveform"
        static let oscillatorDidStart = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidStart"
        static let oscillatorDidStop = "org.themilletgrainfromouterspace.MyTuna.oscillatorDidStop"
        
        static let playTransposeDidChange = "org.themilletgrainfromouterspace.MyTuna.playTransposeDidChange"
        static let referenceTuningHasChanged = "org.themilletgrainfromouterspace.MyTuna.SignalPlayerTuningChanged"
        static let referenceTuningHasChangedObjectKey = "tuningObjectKey"
        
        static let arpeggiatorDidStart = "org.themilletgrainfromouterspace.MyTuna.arpeggiatorDidStart"
        static let arpeggiatorDidStop = "org.themilletgrainfromouterspace.MyTuna.arpeggiatorDidStop"
        
        static let tunerDidStart = "org.themilletgrainfromouterspace.MyTuna.tunerDidStart"
        static let tunerDidUpdate = "org.themilletgrainfromouterspace.MyTuna.tunerDidUpdate"
        static let tunerDidFail = "org.themilletgrainfromouterspace.MyTuna.tunerDidFail"
        static let tunerDidStop = "org.themilletgrainfromouterspace.MyTuna.tunerDidStop"
        static let tunerDidUpdateObjectKey = "tuningUpdateObjectKey"

        static let coreDataImportedCsvKey = "coreDataImportedCsvKey"
        static let coreDataImportedCsvObjectKey = "coreDataImportedCsvObjectKey"
        static let coreDataTuningsShallReloadKey = "coreDataTuningsShallReloadKey"
    }
    
    struct AppDefaultsKeys {
        static let volumeKey = "volumeKey"
        static let thresholdKey = "thresholdKey"
        static let transposeKey = "transposeKey"
        static let lastStandardTuningNotesKey = "lastStandardTuningNotes"
        static let isSpeakerOverriddenKey = "isSpeakerOverridden"
    }
    
    //    struct Path {
    //        static let Documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    //        static let Tmp = NSTemporaryDirectory()
    //    }
}


extension Notification.Name {
    static let mt_coredata_importedCsv = Notification.Name(LJK.NotificationKeys.coreDataImportedCsvKey)

    static let mt_coredata_shallUpdate = Notification.Name(LJK.NotificationKeys.coreDataTuningsShallReloadKey)
    
    static let mt_playTransposeDidChange = Notification.Name(LJK.NotificationKeys.playTransposeDidChange)

    static let mt_oscillatorDidUpdateFrequency = Notification.Name(LJK.NotificationKeys.oscillatorDidUpdateFrequency)
    static let mt_oscillatorDidUpdateWaveform = Notification.Name(LJK.NotificationKeys.oscillatorDidUpdateWaveform)
    static let mt_oscillatorDidStart = Notification.Name(LJK.NotificationKeys.oscillatorDidStart)
    static let mt_oscillatorDidStop = Notification.Name(LJK.NotificationKeys.oscillatorDidStop)
    
    static let mt_referenceTuningHasChanged = Notification.Name(LJK.NotificationKeys.referenceTuningHasChanged)
    
    static let mt_arpeggiatorDidStart = Notification.Name(LJK.NotificationKeys.arpeggiatorDidStart)
    static let mt_arpeggiatorDidStop = Notification.Name(LJK.NotificationKeys.arpeggiatorDidStop)

    static let mt_tunerDidStart = Notification.Name(LJK.NotificationKeys.tunerDidStart)
    static let mt_tunerDidFail = Notification.Name(LJK.NotificationKeys.tunerDidFail)
    static let mt_tunerDidUpdate = Notification.Name(LJK.NotificationKeys.tunerDidUpdate)
    static let mt_tunerDidStop = Notification.Name(LJK.NotificationKeys.tunerDidStop)
}

enum PlayState {
    case playing
    case stopped
}

enum PlayMode {
    case signalgen
    case plucked
    case droning
    case grooving
}

@objc enum WaveForms : Int {
    case sine
    case square
    case triangle
    case sawtooth
}

class MTSignalPlayer: NSObject, AVAudioPlayerDelegate {
    
    static let singleton : MTSignalPlayer = MTSignalPlayer()
    
    let rampTime = 0.2
    var theOscillatorPlayState = PlayState.stopped
    var theArpeggiatorPlayState = PlayState.stopped

    var thePlayMode = PlayMode.grooving

    public var transpose : Bool = false {
        didSet {
            if (transpose != oldValue) {
                initializeStrings(withTuning: currentTuning)
                theFrequency = theFrequency * (transpose ? 2.0 : 1.0)
                NotificationCenter.default.post(name: .mt_playTransposeDidChange, object: nil, userInfo:nil)
                let defaults = UserDefaults.standard
                defaults.set(transpose, forKey: LJK.AppDefaultsKeys.transposeKey)
                defaults.synchronize()
            }
        }
    }
    
    fileprivate var _currentTuning : Tuning?
    public var currentTuning:Tuning {
        get {
            if _currentTuning == nil {
                initializeStringsWithStandardTuning()
                _currentTuning = CoreDataStack.singleton.myStandardGuitarTuningEntity()
            }
            return _currentTuning!
        }
        set {
            if (currentTuning.tuningName != newValue.tuningName) {
                _currentTuning = newValue
                initializeStrings(withTuning:newValue)
                NotificationCenter.default.post(name: .mt_referenceTuningHasChanged, object: nil, userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:newValue])
            }
        }
    }
    
    // MARK: Main volume
    public var theVolume : Double {
        didSet {
            theMixer?.volume = theVolume
            pluckedString.amplitude = theVolume
        }
    }

    public var isPlaying : Bool {
        get {
            return theOscillatorPlayState == .playing || theArpeggiatorPlayState == .playing
        }
    }
    
    // MARK: Oscillator properties
    // osc
    fileprivate let sine = AKTable(.sine, count: 256)
    //    fileprivate let square = AKTable(.square, count: 256)
    //    fileprivate let triangle = AKTable(.triangle, count: 256)
    //    fileprivate let sawtooth = AKTable(.sawtooth, count: 256)
    fileprivate var oscBooster : AKBooster?
    
    fileprivate var oscSine : AKOscillator?
    //    fileprivate let oscSquare : AKOscillator!
    //    fileprivate let oscTriangle : AKOscillator!
    //    fileprivate let oscSawtooth : AKOscillator!
    var theWaveForm = WaveForms.sine
    public var theFrequency : Double {
        didSet {
            if (theFrequency != oldValue) {
                oscSine?.frequency = theFrequency
                NotificationCenter.default.post(name: .mt_oscillatorDidUpdateFrequency,
                                                object: nil,
                                                userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:theFrequency])
                StuffLogger.print("didSet freq= \(theFrequency)")
            }
        }
    }
    
    // particles and fft
    public var fft: AKFFTTap?
    public var amplitudeTracker: AKAmplitudeTracker!

    // MARK: Plucked Instrument
    let pluckedString = AKPluckedString()
    public static let defaultTuning = ["E2", "A2", "D3", "G3", "B3", "E4"]
    
    // Arpeggiator parms
    static let euroTones =  [1.0,9.0/8.0,5.0/4.0,4.0/3.0,3.0/2.0,5.0/3.0,15.0/8.0,2.0/1.0]
    static let ancientGreekTones = [1.0, 32.0/31.0, 16.0/15.0, 4.0/3.0, 3.0/2.0, 48.0/31.0, 8.0/5.0,2.0/1.0]
    static func ratioForNoteNamed(_ noteName:String, atPosition pos:Int) -> Double {
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
    fileprivate var baseMetronome = 0.0

    fileprivate var generator:AKOperationGenerator?
    fileprivate var genBooster: AKBooster?

    fileprivate var theMixer : AKMixer?
    
    public var tunerRunning = false
    fileprivate var microphone: AKMicrophone?
    fileprivate var tracker: AKFrequencyTracker?
    fileprivate var silencemic: AKBooster?
    fileprivate var silencetrk: AKBooster?
    fileprivate let updateInterval: TimeInterval = 0.03
    fileprivate let smoothingBufferCount = 30
    
    public var threshold: Double = 0.1
    public var smoothing: Double = 0.25
    fileprivate var timer: Timer? // Task?
    fileprivate var smoothingBuffer: [Double] = []
    

    
    override init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [LJK.AppDefaultsKeys.thresholdKey:0.2,
                                     LJK.AppDefaultsKeys.volumeKey:0.6,
                                     LJK.AppDefaultsKeys.transposeKey:true,
                                     LJK.AppDefaultsKeys.isSpeakerOverriddenKey: false,
                                     LJK.AppDefaultsKeys.lastStandardTuningNotesKey:CoreDataStack.standardTuningNotes
            ])
        theFrequency = 440.0
        theVolume = 0.6
    }
    
    func completeInitialization() {
        StuffLogger.print("completing initialization..")

        let defaults = UserDefaults.standard
        transpose = defaults.bool(forKey: LJK.AppDefaultsKeys.transposeKey)
        threshold = defaults.double(forKey: LJK.AppDefaultsKeys.thresholdKey)
        theVolume = defaults.double(forKey: LJK.AppDefaultsKeys.volumeKey)
        setupAudioStack()
        isSpeakerOverridden = defaults.bool(forKey: LJK.AppDefaultsKeys.isSpeakerOverriddenKey)
        StuffLogger.print("complete initialization complete.")

    }
    
    // MARK: AUDIO STACK SETUP

    fileprivate var stackLoaded = false
    var isSpeakerOverridden : Bool = false {
        didSet {
            if isSpeakerOverridden {
                do {
                    try AKSettings.session.overrideOutputAudioPort(.speaker)
                    UIDevice.current.isProximityMonitoringEnabled = true
                    NotificationCenter.default.addObserver(self, selector: #selector(proximityStateDidChange(_:)), name: UIDevice.proximityStateDidChangeNotification, object: nil)
                } catch let error as NSError {
                    StuffLogger.print(error)
                }
            } else {
                do {
                    try AKSettings.session.overrideOutputAudioPort(.none)
                    UIDevice.current.isProximityMonitoringEnabled = false
                    NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
                } catch let error as NSError {
                    StuffLogger.print(error)
                }
            }
            if isSpeakerOverridden != oldValue {
                let defaults = UserDefaults.standard
                defaults.set(isSpeakerOverridden, forKey: LJK.AppDefaultsKeys.isSpeakerOverriddenKey)
                defaults.synchronize()
            }
        }
    }
    
    
    
    func setupAudioStack() {
        StuffLogger.print("setting up audio stack..")
        if stackLoaded {
            StuffLogger.print("audio stack already loaded. skipping")
            return
        }
        
        // AudioKit Settings
        AKSettings.fixTruncatedRecordings = true
        #if DEBUG
            AKSettings.enableLogging = true
        #else
            AKSettings.enableLogging = false
        #endif

        do {
            try AKSettings.setSession(category: .playAndRecord)
        } catch let error as NSError {
            StuffLogger.print(error)
        }


        oscSine = AKOscillator(waveform: sine)
        // oscSquare = AKOscillator(waveform: square)
        // oscTriangle = AKOscillator(waveform: triangle)
        // oscSawtooth = AKOscillator(waveform: sawtooth)
        
        oscBooster = AKBooster(oscSine)
        oscBooster!.rampDuration = rampTime
        oscBooster!.gain = 0.0
        
        StuffLogger.print("setting up AKOperationGenerator...")
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
        initializeStringsWithStandardTuning()

        genBooster = AKBooster(generator)
        genBooster!.rampDuration = rampTime
        genBooster!.gain = 0.0
        
        microphone = AKMicrophone()
        tracker = AKFrequencyTracker(microphone)
        silencemic = AKBooster(tracker, gain: 0)
        fft = AKFFTTap(microphone!)
        amplitudeTracker = AKAmplitudeTracker(microphone)
        silencetrk = AKBooster(amplitudeTracker, gain: 0)
        
        theMixer = AKMixer(genBooster, oscBooster, pluckedString, silencemic, silencetrk)
        theMixer?.volume = theVolume
        AudioKit.output = theMixer
        StuffLogger.print("stack loaded = truex")

        stackLoaded = true
    }
    
    func oscillatorFrequency() -> Float {
        return Float(theFrequency)
    }
    
    func oscillatorFrequencyText() -> String? {
        return Formatter.frequency.string(from: NSNumber(value: theFrequency))
    }
    
    // PLUCK
    func triggerPluckedNote(withNoteName name:String) -> Double {
        let freq = prepareFor(noteName: name)
        pluckedString.trigger(frequency: freq)
        return freq
    }
    
    func prepareFor(frequency f : Double) {
        if theFrequency == f { return }
        theFrequency = f
    }
    
    func prepareFor(noteName name:String) -> Double {
        if let note = name.toSinglePitchedNote() {
            return prepareFor(pitchedNote:note)
        } else {
            return 440.0;
        }
    }

    
    func prepareFor(pitchedNote note:MTPitchedNote) -> Double {
        let freq = note.frequency
        prepareFor(frequency:freq)
        return freq
    }
    
    func prepareFor(waveform st:WaveForms) {
        
    }
    
    func prepareFor(signal: SignalEvent) {
        let waveformtype = WaveForms(rawValue:signal.signalType!.intValue)
        prepareFor(waveform:waveformtype!)
        prepareFor(frequency:signal.signalFrequency!.doubleValue)
    }
    
    func restartSignalPlayer() {
        StuffLogger.print("Starting Engines...")
        do {
            try AudioKit.start()
        } catch {
            StuffLogger.print("Cannot start AK");
        }
        microphone?.start()
        oscSine?.play()
        //        let userdefaults = UserDefaults.standard
        //        let lastTuningName = userdefaults.object(forKey: LJK.AppDefaultsKeys.lastTuningNameKey) as? String
        //        if currentTuning == nil || lastTuningName != currentTuning!.tuningName {
        //
        //        }
    }
    
    func teardown() {
        microphone?.stop()
        stopGenerators()
        stopTuner()
        // 20170116
        // suspected crash from iPhoneX simulator when closing debug session
//        DispatchQueue.main.asyncAfter(deadline: .now() + rampTime) {
            StuffLogger.print("Stopped AudioKit.")
        do {
            try AudioKit.stop()
        } catch {
            StuffLogger.print("Cannot stop AK");
        }
//        }
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceProximityStateDidChange, object: nil)
    }
    
    func stopGenerators() {
        stopPlucking()
        stopOscillator()
        pluckedString.stop()
    }
    
    func playOscillator() {
        if theOscillatorPlayState == .playing { return }
        oscBooster?.gain = 1.0
        theOscillatorPlayState = .playing
        NotificationCenter.default.post(name: .mt_oscillatorDidStart, object: nil, userInfo: nil)
        StuffLogger.print("playOscillator \(theFrequency)")
    }
    
    func stopOscillator() {
        if theOscillatorPlayState == .stopped { return }
        oscBooster?.gain = 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + rampTime) {
            self.theOscillatorPlayState = .stopped
            NotificationCenter.default.post(name: .mt_oscillatorDidStop, object: nil, userInfo: nil)
            StuffLogger.print("stoppedOscillator")
        }
    }
    
    func toggleSignal() {
        if theOscillatorPlayState == .playing {
            stopOscillator()
        } else {
            playOscillator()
        }
    }
    
    func toggleTuner() {
        if tunerRunning {
            stopTuner()
        } else {
            startTuner()
        }
    }
    
    fileprivate var lastFrequency = 0.0
    
    /**
     Starts the tuner.
     */
    func startTuner() {
        StuffLogger.print("Activating tuner.")
        if tunerRunning { return }
        microphone?.start()
        tracker?.start()

        if timer != nil {
            timer?.invalidate()
        }
        
        //if timer == nil {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) {
            [weak self] (timer) in
           // guard let this = self else { return }
            
            let amplitude = MTSignalPlayer.singleton.tracker!.amplitude
            let frequency = MTSignalPlayer.singleton.smooth(MTSignalPlayer.singleton.tracker!.frequency)
            
            if (amplitude > (MTSignalPlayer.singleton.threshold/100)) && (abs(frequency - MTSignalPlayer.singleton.lastFrequency) < 20) {
                let output = MTPitchedNote.newOutput(frequency, amplitude)
                StuffLogger.print("frequency = \(frequency)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mt_tunerDidUpdate, object: nil, userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:output])
                }
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .mt_tunerDidFail, object: nil, userInfo: nil)
                }
            }
            MTSignalPlayer.singleton.lastFrequency = frequency
        }
        //}
 
//        if timer == nil {
//            timer = Plan.every(0.03.second).do(queue: .global()) {
//
//                let amplitude = self.tracker!.amplitude
//                let frequency = self.smooth(self.tracker!.frequency)
//
//                if (amplitude > (self.threshold/50)) && (abs(frequency - self.lastFrequency) < 20) {
//                    let output = MTPitchedNote.newOutput(frequency, amplitude)
//                    DispatchQueue.main.async {
//                        NotificationCenter.default.post(name: .mt_tunerDidUpdate, object: nil, userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:output])
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        NotificationCenter.default.post(name: .mt_tunerDidFail, object: nil, userInfo: nil)
//                    }
//                }
//                self.lastFrequency = frequency
//            }
//        }
//        timer?.resume()
        //timer?.fire()
        tunerRunning = true
        NotificationCenter.default.post(name: .mt_tunerDidStart, object: nil, userInfo: nil)
    }
    
    /**
     Stops the tuner.
     */
    func stopTuner() {
        StuffLogger.print("Turning tuner off.")
        if !tunerRunning { return }
        tracker?.stop()
        timer?.invalidate()
        tunerRunning = false
        NotificationCenter.default.post(name: .mt_tunerDidStop, object: nil, userInfo: nil)
    }
    
    /**
     Exponential smoothing:
     https://en.wikipedia.org/wiki/Exponential_smoothing
     */
    fileprivate func smooth(_ value: Double) -> Double {
        var frequency = value
        if smoothingBuffer.count > 0 {
            let last = smoothingBuffer.last!
            frequency = (smoothing * value) + (1.0 - smoothing) * last
            if smoothingBuffer.count > smoothingBufferCount {
                smoothingBuffer.removeFirst()
            }
        }
        smoothingBuffer.append(frequency)
        return frequency
    }

    // MARK: Proximity notif
    var lastVolumeValueBeforeProximity = 0.6
    @objc func proximityStateDidChange(_ notification: Notification) {
        if UIDevice.current.proximityState {
            lastVolumeValueBeforeProximity = theVolume
            if theVolume > 0.1 {
                StuffLogger.print("proximityDidChamge damping...")
                theVolume = 0.05
            }
        } else {
            StuffLogger.print("proximityDidChamge restoring.")

            theVolume = lastVolumeValueBeforeProximity
        }
    }
    
    // MARK: Utils
    
    func checkMicPermission(withPresentingViewController vc:UIViewController?) -> Bool {
        var permissionCheck: Bool = false
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            permissionCheck = true
            break
        case AVAudioSession.RecordPermission.denied:
            //            self.listenButton.title = "Enable"
            if (vc != nil) {
                let controller = UIAlertController(title: "Permissions denied", message: "Grant the permissions in iOS Settings", preferredStyle: UIAlertController.Style.alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) in
                    
                })
                controller.addAction(cancelAction)
                
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                
                            })
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(settingsUrl)
                        }
                    }
                }
                controller.addAction(settingsAction)
                vc!.present(controller, animated: true, completion: nil)
            }
            permissionCheck = false
            break
        default:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                    //                    self.listenButton.title = "OFF"
                } else {
                    //                    self.listenButton.title = "Enable"
                }
            })
        }
        
        if (permissionCheck) {
            //            self.listenButton.title = "OFF"
            
        } else {
            //            self.listenButton.title = "Enable"
            
        }
        return permissionCheck
    }
    
    
    // MARK: AK
    
    // MARK: AK Osc
    
    func oscilloSineNode(frequency: Float) -> AKOperation {
        switch (theWaveForm) {
        case .sine:
            return AKOperation.sineWave(frequency: frequency, amplitude: 0.5)
        case .square:
            return AKOperation.square(frequency: frequency, amplitude: 0.5, phase: 0.0)
        case .sawtooth:
            return AKOperation.sawtoothWave(frequency: frequency, amplitude: 0.5)
        case .triangle:
            return AKOperation.triangleWave(frequency: frequency, amplitude: 0.5)
        }
    }

    func togglePlucking() {
        if theArpeggiatorPlayState == .playing {
            stopPlucking()
        } else {
            startPlucking()
        }
    }
    
    // MARK: AK PLUCKED
    func startPlucking() {
        if theArpeggiatorPlayState == .playing { return }
        stopTuner()
        genBooster!.gain = 1.0
        
        if let theGenerator = generator {
            theGenerator.start()
            theArpeggiatorPlayState = .playing
            NotificationCenter.default.post(name: .mt_arpeggiatorDidStart, object: nil, userInfo: nil)
        }
    }
    
    func stopPlucking() {
        if theArpeggiatorPlayState == .stopped {
            return
        }
        genBooster!.gain = 0.0
        self.theArpeggiatorPlayState = .stopped

        DispatchQueue.main.asyncAfter(deadline: .now() + rampTime) {
            if let theGenerator = self.generator {
                theGenerator.stop()
                NotificationCenter.default.post(name: .mt_arpeggiatorDidStop, object: nil, userInfo: nil)
            }
        }
    }

    // play groove
    func instrument(noteIdentity: Double, rate: Double, amplitude: Double) -> AKOperation {
        let metro = AKOperation.metronome(frequency:rate )
        let frequency = noteIdentity
        return AKOperation.pluckedString(trigger: metro,frequency:frequency)
    }
    
    // just pluck
    func plukNode(frequency: Float) -> AKOperation {
        return AKOperation.pluckedString(
            trigger: AKOperation.trigger,
            frequency: frequency,
            amplitude: 0.5,
            lowestFrequency: 50)
    }

    func pluckNode(frequency freq:Double) -> AKOperationGenerator {
        return AKOperationGenerator { parameters in
            let frequency = parameters[0]
            return AKOperation.pluckedString(
                trigger: AKOperation.trigger,
                frequency: frequency,
                amplitude: 0.5,
                lowestFrequency: 50)
        }
    }

    func initializeStringsWithStandardTuning() {
        StuffLogger.print("initializing default generator notes")
        if let theGenerator = generator {
            for (i, notename) in MTSignalPlayer.defaultTuning.enumerated() {
                if let note = notename.toSinglePitchedNote() {
                    let f = note.frequency * (self.transpose ? 2.0 : 1.0)
                    let theBeat = MTSignalPlayer.ratioForNoteNamed(note.noteNameSharp, atPosition:i) * baseMetronome
                    theGenerator.parameters[i] = f
                    theGenerator.parameters[i + 7] = theBeat
                }
            }
        }
    }
    
//    func initializeStrings(withTuningProxy tuningProxy:MTTuningProxy) {
//        // adapt tuning to strings generators
//        var baseMetronome = 0.0
//        switch thePlayMode {
//        case .droning:
//            baseMetronome = 0.0
//        case .plucked:
//            baseMetronome = -1.0
//        case .grooving:
//            baseMetronome = 1.0
//        default: break
//        }
//
//        if let theGenerator = generator {
//            let notes = tuningProxy.tuningNotes
//            var i = 0
//            for note in notes {
//                if (i < 7) {
//                    let f = note.frequency * (1 + transpose)
//                    var theBeat = MTSignalPlayer.ratioForNoteNamed(note.noteNameSharp, atPosition:i) * baseMetronome
//                    if theBeat == 0 {
//                        theBeat = 0.2
//                    }
//                    theGenerator.parameters[i] = f
//                    theGenerator.parameters[i + 7] = theBeat
//                }
//                i += 1
//            }
//        }
//
//    }
    
    // called in currentTuning didSet
    public func initializeStrings(withTuning targetTuning:Tuning) {
        StuffLogger.print("didSet tuning \(String(describing: targetTuning.tuningName))")
        // adapt tuning to strings generators
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
            let notes = targetTuning.tuningPitchedNotes()
            var i = 0
            for note in notes {
                if (i < 7) {
                    let f = note.frequency * (transpose ? 2.0 : 1.0)
                    var theBeat = MTSignalPlayer.ratioForNoteNamed(note.noteNameSharp, atPosition:i) * baseMetronome
                    if theBeat == 0 {
                        theBeat = 0.2
                    }
                    theGenerator.parameters[i] = f
                    theGenerator.parameters[i + 7] = theBeat
                }
                i += 1
            }
        }

    }
}

// MARK: Tuning extension for Pitched Note

extension Tuning {
    func tuningPitchedNotes() -> [MTPitchedNote] {
        return self.tuningNotes!.toPitchedNotes()
    }
    
    func updateWith(arrayOfPitchedNotes notes:[MTPitchedNote]) {
        let noteNames = notes.compactMap({ (note) -> String? in
            return note.string
        })
        let nuTuningString = noteNames.joined(separator: "-")
        StuffLogger.print("updated tuning notes \(nuTuningString)")
        MTSignalPlayer.singleton.currentTuning.tuningNotes = nuTuningString
        MTSignalPlayer.singleton.initializeStrings(withTuning: MTSignalPlayer.singleton.currentTuning)
        NotificationCenter.default.post(name: .mt_referenceTuningHasChanged, object: nil, userInfo: [LJK.NotificationKeys.referenceTuningHasChangedObjectKey:MTSignalPlayer.singleton.currentTuning])

    }
}
