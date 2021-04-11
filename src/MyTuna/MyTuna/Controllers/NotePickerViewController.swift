//
//  NotePickerViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 09/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

protocol NotePickerViewControllerDelegate : class {
    func notePicker(scrolledToNote note:MTPitchedNote)
    func notePickerShouldEnableEditing() -> Bool
}

class NotePickerViewController: BaseViewController {

    
    static let NotePickerViewControllerStoryboardName = "Main"
    static let NotePickerViewControllerStoryboardVCID = "NotePickerVCID"
    
//    static func presentNotePickerVc(fromTuningSegmentControl tuningSc:MTTuningSegmentControl) {
//        let numofSegs = CGFloat(tuningSc.numberOfSegments)
//        let selectedSegmentIndex = CGFloat(tuningSc.selectedSegmentIndex)
//        let ancrect = CGRect(x:(tuningSc.frame.size.width/numofSegs * selectedSegmentIndex), y:0, width: tuningSc.frame.size.width/numofSegs, height: tuningSc.bounds.size.height)
//
//        let storyboard = UIStoryboard(name: NotePickerViewControllerStoryboardName, bundle: nil)
//        let controller = storyboard.instantiateViewController(withIdentifier: NotePickerViewControllerStoryboardVCID) as! NotePickerViewController
//        controller.delegate = tuningSc
//
//        tuningSc.mt_presentingVc?.navigationController?.modalPresentationStyle = .popover
//        if let pctrl = tuningSc.mt_presentingVc?.popoverPresentationController {
//            pctrl.delegate = controller
//            pctrl.sourceRect = ancrect
//            pctrl.sourceView = tuningSc
//        }
//        controller.targetNote = tuningSc.mt_tappedNote
//        tuningSc.mt_presentingVc?.present(controller, animated: true, completion: nil)
//    }
    
    @IBOutlet weak var notePickerView: UIPickerView!
    
    @IBOutlet weak var diapasonButton: UIBarButtonItem!
    public weak var delegate : NotePickerViewControllerDelegate!
    public var targetNote : MTPitchedNote!

    fileprivate var lastSelectedIndexSemitone = 0
    fileprivate var lastSelectedIndexOctave = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notePickerView.delegate = self
        notePickerView.dataSource = self
    }
    
    func addObservers() {
        StuffLogger.print("Adding obs")
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStart, object: nil, queue: nil) { (note) in
            self.diapasonButton.image = UIImage(named:"diapasonOnIcon")
        }
        NotificationCenter.default.addObserver(forName: .mt_oscillatorDidStop, object: nil, queue: nil) { (note) in
            self.diapasonButton.image = UIImage(named:"diapasonOffIcon")
        }
    }
    
    func removeObservers() {
        StuffLogger.print("Removing obs")
        NotificationCenter.default.removeObserver(self, name: .mt_oscillatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_oscillatorDidStop, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTSignalPlayer.singleton.stopOscillator()

        addObservers()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
        MTSignalPlayer.singleton.stopOscillator()
    }
    
    @IBAction func diapasonButtonAction(_ sender: UIBarButtonItem) {
        let _ = MTSignalPlayer.singleton.prepareFor(pitchedNote: targetNoteFromPicker())
        
        MTSignalPlayer.singleton.toggleSignal()
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
//        let nuNote = targetNoteFromPicker()
//        targetNote = nuNote
        delegate.notePicker(scrolledToNote: targetNote)
        dismiss(animated: true, completion: nil)
    }
    
    
    func targetNoteFromPicker() -> MTPitchedNote {
        let semitone = notePickerView.selectedRow(inComponent: 0)
        let octave = notePickerView.selectedRow(inComponent: 1)
        return MTPitchedNote(withOctave:octave, andSemitone:semitone)
    }
    
    func updateUI() {
        lastSelectedIndexSemitone = targetNote.semitone
        lastSelectedIndexOctave = targetNote.octave
        notePickerView.selectRow(lastSelectedIndexSemitone, inComponent: 0, animated: true)
        notePickerView.selectRow(lastSelectedIndexOctave, inComponent: 1, animated: true)
    }

}


extension NotePickerViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if delegate.notePickerShouldEnableEditing() {
            let note = targetNoteFromPicker()
            let _ = MTSignalPlayer.singleton.prepareFor(pitchedNote: note)
            switch (component) {
            case 0:
                lastSelectedIndexSemitone = row
            default:
                lastSelectedIndexOctave = row
            }
            delegate.notePicker(scrolledToNote: note)
        } else {
            // reset to original positions
            switch (component) {
            case 0:
                notePickerView.selectRow(lastSelectedIndexSemitone, inComponent: 0, animated: true)
            default:
                notePickerView.selectRow(lastSelectedIndexOctave, inComponent: 1, animated: true)
            }
        }
    }
}


extension NotePickerViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (component) {
        case 0:
            return MTPitchedNote.sharps.count
        default:
            return 9
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return MTPitchedNote.sharps[row]
        } else {
            return String(row)
        }
    }
}
