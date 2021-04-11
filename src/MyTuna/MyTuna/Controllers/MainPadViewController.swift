//
//  MainPadViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class MainPadViewController: UIViewController {
    func oscillator(didChangeFrequency frequency: Double) {
        updateFrequencyText()

    }
    
    func oscillator(didChangePlayingStatus playing: Bool) {
        
    }
    
    func tunerDidUpdate(_ noteNameLabelString: String, gaugeDiff: Float) {
        self.gaugeView.value = gaugeDiff
        self.pitchLabel.text = noteNameLabelString
    }
    
    // MARK: Properties

    // TUNER
    @IBOutlet weak var gaugeView: WMGaugeView!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var micAudioPlot: EZAudioPlot!
    
    
    // SIGGEN
    @IBOutlet weak var frequencyWaveformSegmentControl: UISegmentedControl!
    @IBOutlet weak var frequencyTextField: UITextField!
    @IBOutlet weak var signalAudioPlot: EZAudioPlot!
    
    func setupTunerGauge(withGaugeView gaugeView : WMGaugeView) {
        gaugeView.style = WMGaugeViewStyle3D()
        
        gaugeView.maxValue = 50.0
        gaugeView.minValue = -50.0
        //        gaugeView.needleWidth = 0.01
        //        gaugeView.needleHeight = 0.4
        gaugeView.scaleDivisions = 10
        gaugeView.scaleEndAngle = 270
        gaugeView.scaleStartAngle = 90
        gaugeView.scaleSubdivisions = 5
        gaugeView.showScaleShadow = false
        //        gaugeView.needleScrewRadius = 0.05
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

    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        MTSignalPlayer.singleton.setupPlot(micPlotView: micAudioPlot)
        //MTSignalPlayer.singleton.setupPlot(signalPlotView: signalAudioPlot)

    }

    override func viewDidAppear(_ animated: Bool) {
        
        updateUI()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func tunerActivationAction(_ sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == 0) {
            MTSignalPlayer.singleton.stopTuner()
        } else {
            MTSignalPlayer.singleton.startTuner()
        }
    }
    
    @IBAction func playSignalButtonAction(_ sender: UIButton) {
        MTSignalPlayer.singleton.toggleSignal()
    }
    
    @IBAction func frequencySliderChangedAction(_ sender: UISlider) {
        MTSignalPlayer.singleton.prepareFor(frequency: Double(sender.value))
        updateFrequencyText()
    }
    
    @IBAction func frequencyWaveformSegmentControlAction(_ sender: UISegmentedControl) {
        let waveformtype = WaveForms(rawValue:sender.selectedSegmentIndex)
        MTSignalPlayer.singleton.prepareFor(waveform: waveformtype!)
    }

    
    func updateUI() {
        updateFrequencyText()
    }
    
    func updateFrequencyText() {
        frequencyTextField.text = MTSignalPlayer.singleton.oscillatorFrequencyText()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
