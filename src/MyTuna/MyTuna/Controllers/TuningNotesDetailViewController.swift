//
//  TuningNotesDetailViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 09/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

class TuningNotesDetailViewController: BaseViewController {
    //    public weak var targetTuning : Tuning?
    fileprivate var targetTuning : Tuning {
        return MTSignalPlayer.singleton.currentTuning
    }

    
    
    
    // MARK: Reversable array management
    func normalizedIndexForNoteList(_ index:Int) -> Int {
        let n = noteList.count
        return n - (index > n ? n : index) - 1
    }
    
    func noteAtReversedIndex(_ index:Int) -> MTPitchedNote {
        let index = normalizedIndexForNoteList(index)
        return noteList[index]
    }
    
    func swapNotesAtReversedIndexes(sourceIndex index1:Int, destIndex index2:Int) {
        let source = normalizedIndexForNoteList(index1)
        let dest = normalizedIndexForNoteList(index2)
        let movedObject = self.noteList[source]
        noteList.remove(at: source)
        noteList.insert(movedObject, at: dest)
    }
    
    fileprivate let cellIdentifier = "noteOnStringCell"
    fileprivate var noteList = [MTPitchedNote]()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var originalOrderLabel: UILabel!
    
    @IBAction func restoreButtonAction(_ sender: UIButton) {
        let originalString = originalOrderLabel.text!
        noteList = originalString.toPitchedNotes()
        tableView.reloadData()
        sender.isEnabled = false
        isEditing = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: Actions
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.tableView.isEditing = editing
        addButtonItem.isEnabled = editing
        if (!editing) {
            MTSignalPlayer.singleton.currentTuning.updateWith(arrayOfPitchedNotes: self.noteList)
            CoreDataStack.singleton.saveContext()
        } else {
            self.tableView.reloadData()
        }
        super.setEditing(editing, animated: animated)
    }
    

    @IBAction func addNoteButtonAction(_ sender: UIBarButtonItem) {
        if (noteList.count >= CoreDataStack.maxTuningNotesAccepted) {
            showAlert(withTitle: "Strings Limit", andMessage: "This version supports only up to \(CoreDataStack.maxTuningNotesAccepted) strings per tuning.")
        } else {
            if let nuNote = "A4".toSinglePitchedNote() {
                noteList.append(nuNote)
                tableView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var arpeggiatorButton: UIBarButtonItem!
    @IBAction func arpeggiatorButtonAction(_ sender: UIBarButtonItem) {
        MTSignalPlayer.singleton.togglePlucking()
    }

    // MARK: Observation
    
    func addObservers() {
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStart, object: nil, queue: nil) { (note) in
            self.arpeggiatorButton.image = UIImage(named:"PauseIcon")
        }
        NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStop, object: nil, queue: nil) { (note) in
            self.arpeggiatorButton.image = UIImage(named:"PlayIcon")
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStop, object: nil)
    }
    

    
    // MARK: ViewController Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
//        MTSignalPlayer.singleton.thePlayMode = .plucked
        addObservers()
        noteList = targetTuning.tuningPitchedNotes()
        originalOrderLabel.text = targetTuning.tuningNotes
        restoreButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        MTSignalPlayer.singleton.thePlayMode = .grooving
        removeObservers()
    }
    
    func reversedTuningNotes() -> String {
//        let reversed : [MTPitchedNote] = noteList.reversed()
        targetTuning.updateWith(arrayOfPitchedNotes: noteList) // it will send notif
        CoreDataStack.singleton.saveContext()
        return targetTuning.tuningNotes!
    }
    
    func checkRestoreButtonEnabled() {
        let nuNotes = reversedTuningNotes()
        restoreButton.isEnabled = nuNotes != originalOrderLabel.text
    }
}

extension TuningNotesDetailViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        swapNotesAtReversedIndexes(sourceIndex: sourceIndexPath.row, destIndex: destinationIndexPath.row)
//        let movedObject = self.noteList[sourceIndexPath.row]
//        noteList.remove(at: sourceIndexPath.row)
//        noteList.insert(movedObject, at: destinationIndexPath.row)
        tableView.reloadData()
        checkRestoreButtonEnabled()

//        NSLog("%@", "\(sourceIndexPath.row) => \(destinationIndexPath.row) \(fruits)")
        // To check for correctness enable: self.tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //        let noteName = noteList[indexPath.row]
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
//            self.noteList.remove(at: indexPath.row)
            let note = self.normalizedIndexForNoteList(indexPath.row)//noteList[indexPath.row]
            self.noteList.remove(at: note)

            self.tableView.reloadData()
            self.checkRestoreButtonEnabled()
        }
        deleteAction.backgroundColor = UIColor.red
        return [deleteAction]
    }

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == MTTuningSegmentControl.popoverNoteEditSegueName {
            let noteEditorVc = segue.destination as! NotePickerViewController
            if let senderButton = sender as? MTNoteButton {
                noteEditorVc.delegate = senderButton
                if let pctrl = segue.destination.popoverPresentationController {
                    pctrl.delegate = self
                    pctrl.sourceRect = senderButton.bounds
                    pctrl.sourceView = senderButton
                }
                noteEditorVc.targetNote = senderButton.mt_tappedNote
            }
        }
    }

}


extension TuningNotesDetailViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! NoteOnStringTableViewCell
        cell.delegate = self
        let note = noteAtReversedIndex(indexPath.row)//noteList[indexPath.row]
        let notaName = note.string
        
        cell.cellIndex = indexPath
        cell.noteOnStringButton.isSelected = self.isEditing
        cell.noteOnStringButton.setTitle(notaName, for: .normal)
        cell.noteOnStringButton.mt_tappedNote = note
        
        cell.noteOnStringLabel.text = String(indexPath.row + 1)
        return cell
    }

}

extension TuningNotesDetailViewController : NoteOnStringTableViewCellDelegate {
    func didChangeNote(onCell targetCell: NoteOnStringTableViewCell) {
        let index = normalizedIndexForNoteList(targetCell.cellIndex!.row)
        noteList[index] = targetCell.noteOnStringButton!.mt_tappedNote!
        checkRestoreButtonEnabled()
    }
    
    
    func didTap(onNoteButton noteButton: MTNoteButton) {
        if self.isEditing {
            performSegue(withIdentifier: MTTuningSegmentControl.popoverNoteEditSegueName, sender: noteButton)
        }
    }
    
    
}


protocol NoteOnStringTableViewCellDelegate : class {
    func didTap(onNoteButton noteButton: MTNoteButton)
    func didChangeNote(onCell targetCell:NoteOnStringTableViewCell)
}

class NoteOnStringTableViewCell : UITableViewCell {
    
    var cellIndex : IndexPath?
    weak var delegate : NoteOnStringTableViewCellDelegate?
    
    @IBOutlet weak var noteOnStringButton: MTNoteButton!
    @IBOutlet weak var noteOnStringLabel: UILabel!
    
    override func awakeFromNib() {
        noteOnStringButton.delegate = self
    }
    
    @IBAction func noteButtonAction(_ sender: MTNoteButton) {
        delegate?.didTap(onNoteButton: sender)
    }
}

extension NoteOnStringTableViewCell : MTNoteButtonDelegate {
    func didSetNewNote(_ newNote: MTPitchedNote) {
        delegate?.didChangeNote(onCell: self)
    }
}

protocol MTNoteButtonDelegate : class {
    func didSetNewNote(_ newNote:MTPitchedNote)
}

class MTNoteButton : UIButton, NotePickerViewControllerDelegate {
    var mt_tappedNote : MTPitchedNote?
    weak var delegate : MTNoteButtonDelegate?
    func notePicker(scrolledToNote note: MTPitchedNote) {
        self.setTitle(note.string, for: .normal)
        mt_tappedNote = note
        delegate?.didSetNewNote(note)
    }
    
    func notePickerShouldEnableEditing() -> Bool {
        return true
    }
    
    
}

