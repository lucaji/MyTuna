//
//  MTTuningSegmentControl.swift
//  MyTuna
//
//  Created by Luca Cipressi on 25/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

protocol MTTuningSegmentControlDelegate : class {
    func tuningSegmentControl(didUpdate tuningNotes:[MTPitchedNote])
}

class MTTuningSegmentControl: UISegmentedControl {
    
    public static let popoverNoteEditSegueName = "detailToNoteEditPopoverSegue"

    public var mt_presentingVc : BaseViewController?
    @IBInspectable public var tuningEditingIsEnabled = false
    
    public weak var delegate : MTTuningSegmentControlDelegate?
    fileprivate var tuningNotes = [MTPitchedNote]()
    
    public var mt_tappedNote : MTPitchedNote {
        return tuningNotes[lastTappedIndex]
    }
    
    var tuningHasChanged : Bool = false
    
    
    
    fileprivate var lastTappedIndex = -1
    override func awakeFromNib() {
//        self.addTarget(self, action: #selector(mt_changedSegmentedControlValue(sender:)), for: .valueChanged)
        super.awakeFromNib()
        let segmentedTapGesture = UITapGestureRecognizer(target: self, action: #selector(mt_tappedOnSegmentedControl(sender:)))
        self.addGestureRecognizer(segmentedTapGesture)
    }
    
    @objc func mt_tappedOnSegmentedControl(sender:UITapGestureRecognizer) {
        let point = sender.location(in: self)
        let segmentSize = self.bounds.size.width / CGFloat(self.numberOfSegments)
        lastTappedIndex = Int(point.x / segmentSize)
        if self.selectedSegmentIndex != lastTappedIndex {
            // Normal behaviour the segment changes
        } else {
            // Tap on the already selected segment
        }
        if self.isMomentary && !tuningEditingIsEnabled {
//            MTSignalPlayer.singleton.triggerPluckedNote(withNoteName: self.titleForSegment(at: lastTappedIndex)!)
        }
        if !self.isMomentary {
            self.selectedSegmentIndex = lastTappedIndex
        }
        if tuningEditingIsEnabled {
            mt_presentingVc?.performSegue(withIdentifier: MTTuningSegmentControl.popoverNoteEditSegueName, sender: self)
            //            NotePickerViewController.presentNotePickerVc(fromTuningSegmentControl: self)
        }
    }
    
    func mt_configure(withTuning tuning:Tuning, andPresentingViewController presentingVc:BaseViewController) {
        mt_presentingVc = presentingVc
        tuningNotes = tuning.tuningPitchedNotes()
        if (tuningNotes.count > self.numberOfSegments) {
            let addo = tuningNotes.count - self.numberOfSegments
            for _ in 1...addo {
                self.insertSegment(withTitle: "", at: 0, animated: false)
            }
        } else if (tuningNotes.count < self.numberOfSegments) {
            let subo = self.numberOfSegments - tuningNotes.count
            for _ in 1...subo {
                self.removeSegment(at: 0, animated: false)
            }
        }
        for index in 0...(tuningNotes.count-1) {
            self.setTitle(tuningNotes[index].string, forSegmentAt: index)
        }
        self.isSelected = false
    }
}

extension MTTuningSegmentControl : NotePickerViewControllerDelegate {
    func notePickerShouldEnableEditing() -> Bool {
        return tuningEditingIsEnabled
    }
    
    func notePicker(scrolledToNote note: MTPitchedNote) {
        self.setTitle(note.string, forSegmentAt: lastTappedIndex)
        var nuTuning = [MTPitchedNote]()
        for (i, note) in tuningNotes.enumerated() {
            let nuNoteTitle = self.titleForSegment(at: i) ?? "A4"
            if let nuNote = nuNoteTitle.toSinglePitchedNote() {
                nuTuning.append(nuNote)
            }
            if note.string != nuNoteTitle {
                tuningHasChanged = true
            }
        }
        tuningNotes = nuTuning
        delegate?.tuningSegmentControl(didUpdate: tuningNotes)
    }
    
    
}
