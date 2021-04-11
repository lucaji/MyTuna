//
//  TuningDetailsViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

class TuningDetailsViewController: BaseViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var commentsTextField: UITextView!

    @IBOutlet weak var tuningTypeButton: UIButton!
    @IBOutlet weak var tuningInstrumentButton: UIButton!
    
    @IBOutlet weak var tuningSegmentedControl: MTTuningSegmentControl!
    
    fileprivate let segueName = "editTuningNotesSegue"
//    fileprivate var _hasChanges = false
//    fileprivate var hasChanges : Bool {
//        get {
//            return _hasChanges
//        }
//        set {
//            _hasChanges = newValue
//            if self.isEditing {
//                saveButton.title = _hasChanges ? "Save" : "Cancel"
//            } else {
//                saveButton.title = "Edit"
//            }
//        }
//    }
    
    
    @IBOutlet weak var addTuningTypeButton: UIButton!
    @IBOutlet weak var addTuningInstrumentButton: UIButton!
    
    @IBAction func addTuningTypeButtonAction(_ sender: UIButton) {
        addTuningTypeAlert { (ttype) in
            MTSignalPlayer.singleton.currentTuning.tuningType = ttype
            CoreDataStack.singleton.saveContext()
        }
    }
    
    @IBAction func addTuningInstrumentButtonAction(_ sender: UIButton) {
        addInstrumentAlert { (instro) in
            MTSignalPlayer.singleton.currentTuning.tuningInstrument = instro
            CoreDataStack.singleton.saveContext()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if (!editing) {
            CoreDataStack.singleton.saveContext()
        }
        tuningTypeButton.isEnabled = editing
        tuningTypeButton.isSelected = editing
        
        tuningInstrumentButton.isEnabled = editing
        tuningInstrumentButton.isSelected = editing
        
        addTuningTypeButton.isEnabled = editing
        addTuningInstrumentButton.isEnabled = editing
        
        // text fields
        nameTextField.isEnabled = editing
        commentsTextField.isEditable = editing
        tuningSegmentedControl.tuningEditingIsEnabled = editing
        
        // textfield coloring
        UIView.animate(withDuration: 0.5) {
            if editing {
                self.nameTextField.textColor = UIColor.black
                self.nameTextField.backgroundColor = UIColor.white
                
                self.commentsTextField.textColor = UIColor.black
                self.commentsTextField.backgroundColor = UIColor.white
            } else {
                self.nameTextField.textColor = UIColor.lightText
                self.nameTextField.backgroundColor = UIColor.darkText
                
                self.commentsTextField.textColor = UIColor.lightText
                self.commentsTextField.backgroundColor = UIColor.darkText
            }
        }
        super.setEditing(editing, animated: animated)
    }

    
//    public weak var targetTuning : Tuning?
    fileprivate var targetTuning : Tuning {
        return MTSignalPlayer.singleton.currentTuning
    }
    
    // MARK: Viewcontroller Lifecycle
    func addObservers() {
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStart, object: nil, queue: nil) { (note) in
            self.arpeggiatoButton.image = UIImage(named:"PauseIcon")
        }
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStop, object: nil, queue: nil) { (note) in
            self.arpeggiatoButton.image = UIImage(named:"PlayIcon")
        }
        NotificationCenter.default.addObserver(forName: .mt_coredata_shallUpdate, object: nil, queue: nil) { (note) in
            self.updateUI()
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStop, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_coredata_shallUpdate, object: nil)
    }
    
    func updateUI() {
        nameTextField.text = targetTuning.tuningName
        tuningSegmentedControl.mt_configure(withTuning: targetTuning, andPresentingViewController: self)
        commentsTextField.text = targetTuning.tuningComments
        tuningInstrumentButton.setTitle(targetTuning.tuningInstrument?.instrumentName, for: .normal)
        tuningTypeButton.setTitle(targetTuning.tuningType?.tuningTypeName, for: .normal)
    }
    
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = self.editButtonItem
//        hasChanges = false
        commentsTextField.delegate = self
        commentsTextField.layer.borderWidth = 2
        commentsTextField.layer.borderColor = UIColor.lightGray.cgColor
        commentsTextField.layer.cornerRadius = 8.0
        commentsTextField.clipsToBounds = true
        nameTextField.delegate = self
        tuningSegmentedControl.delegate = self
        tuningSegmentedControl.tuningEditingIsEnabled = true
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
//    func configureWithTuning(_ tuning:Tuning) {
//        targetTuning = tuning
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        isEditing = false
        updateUI()
    }

    // MARK: Actions
    
    @IBOutlet weak var addNewItemButton: UIBarButtonItem!
    @IBAction func addNewItemButtonAction(_ sender: UIBarButtonItem) {
        CoreDataStack.singleton.saveContext()
        let curTuning = MTSignalPlayer.singleton.currentTuning
        MTSignalPlayer.singleton.currentTuning = CoreDataStack.singleton.duplicateTuning(curTuning)
        self.isEditing = true
    }
    
    
    @IBOutlet weak var arpeggiatoButton: UIBarButtonItem!
    @IBAction func arpeggiatoButtonAction(_ sender: UIBarButtonItem) {
        MTSignalPlayer.singleton.togglePlucking()
    }
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBAction func deleteButtonAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Confirm Deletion", message: "Remove \(targetTuning.tuningName!)?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in }
        alertController.addAction(cancelAction)
        let deleteAction = UIAlertAction(title: "Remove", style: .destructive) { action in
            CoreDataStack.singleton.deleteTuningInPersistentStore(self.targetTuning)
            MTSignalPlayer.singleton.currentTuning = CoreDataStack.singleton.myStandardGuitarTuningEntity()
            self.navigationController?.popViewController(animated: true)
        }
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var stringMappingButton: UIBarButtonItem!
    @IBAction func stringsMappingButtonAction(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: segueName, sender: self)
    }
    
    @IBAction func tuningTypeButtonAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose Category", message: "Assign a tuning category to \(targetTuning.tuningName!):", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        alertController.addAction(cancelAction)

        for ttype in CoreDataStack.singleton.allTuningTypes() {
            let OKAction = UIAlertAction(title: ttype.tuningTypeName, style: .default) { _ in
                self.targetTuning.tuningType = ttype
                CoreDataStack.singleton.saveContext()
                self.tuningTypeButton.setTitle(ttype.tuningTypeName, for: .normal)
//                self.hasChanges = true
            }
            alertController.addAction(OKAction)
        }
        
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.delegate = self;
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func tuningInstrumentButtonAction(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose Instrument", message: "Assign an instrument to \(targetTuning.tuningName!):", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        alertController.addAction(cancelAction)
        
        for instro in CoreDataStack.singleton.allInstruments() {
            let OKAction = UIAlertAction(title: instro.instrumentName, style: .default) { _ in
                self.targetTuning.tuningInstrument = instro
//                self.hasChanges = true
                CoreDataStack.singleton.saveContext()

                self.tuningInstrumentButton.setTitle(instro.instrumentName, for: .normal)
            }
            alertController.addAction(OKAction)
        }
        
        alertController.modalPresentationStyle = .popover
        alertController.popoverPresentationController?.delegate = self;
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueName {
//            let tuningVc = segue.destination as! TuningNotesDetailViewController
//            tuningVc.targetTuning = targetTuning
        } else if segue.identifier == MTTuningSegmentControl.popoverNoteEditSegueName {
            let noteEditorVc = segue.destination as! NotePickerViewController
            if let tuningSc = sender as? MTTuningSegmentControl {
                noteEditorVc.delegate = tuningSc
                let numofSegs = CGFloat(tuningSc.numberOfSegments)
                let selectedSegmentIndex = CGFloat(tuningSc.selectedSegmentIndex)
                let ancrect = CGRect(x:(tuningSc.frame.size.width/numofSegs * selectedSegmentIndex), y:0, width: tuningSc.frame.size.width/numofSegs, height: tuningSc.bounds.size.height)
                if let pctrl = segue.destination.popoverPresentationController {
                    pctrl.delegate = self
                    pctrl.sourceRect = ancrect
                    pctrl.sourceView = tuningSc
                }
                noteEditorVc.targetNote = tuningSc.mt_tappedNote
            }
        }
    }
    

}

// MARK: - UITextViewdDelegate

extension TuningDetailsViewController: UITextViewDelegate {
    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        // Call resignFirstResponder when the user presses the Return key
//        if text.rangeOfCharacter(from: CharacterSet.newlines) != nil {
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
    
    func textViewDidChange(_ textView: UITextView) {
        if (targetTuning.tuningComments != textView.text) {
//            self.hasChanges = true
        }
        targetTuning.tuningComments = textView.text
    }
    
}

// MARK: UITextField Delegate

extension TuningDetailsViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Call resignFirstResponder when the user presses the Return key
        if string.rangeOfCharacter(from: CharacterSet.newlines) != nil {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == nameTextField {
            if (targetTuning.tuningName != textField.text) {
//                self.hasChanges = true
            }
            targetTuning.tuningName = textField.text
        }
    }
}

// MARK: MTTuningSegmentControlDelegate

extension TuningDetailsViewController : MTTuningSegmentControlDelegate {
    func tuningSegmentControl(didUpdate tuningNotes: [MTPitchedNote]) {
        if tuningSegmentedControl.tuningHasChanged {
//            hasChanges = true
//            saveButton.title = "Save"
            targetTuning.updateWith(arrayOfPitchedNotes: tuningNotes)
            CoreDataStack.singleton.saveContext()

        }
    }
    
    
}
