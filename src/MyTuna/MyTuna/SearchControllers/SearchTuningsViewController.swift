//
//  SearchTuningsViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 26/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit
import CoreData

class SearchTuningsViewController: BaseViewController, TuningTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate {
   
    var lastSelectedCellIndex : IndexPath? = nil
    
    var callingTuningSegmentedControl : MTTuningSegmentControl?
    func tuningSegmentedControlAction(withPitchedNote note: MTPitchedNote, andAnchorView anchor: MTTuningSegmentControl) {
       let freq = MTSignalPlayer.singleton.prepareFor(pitchedNote: note)
        print(freq)
        callingTuningSegmentedControl = anchor
//        performSegue(withIdentifier: "popoverNoteEdit", sender: note)
    }
    
    // MARK: TuningPlay Action
    
    @IBOutlet weak var arpeggiatorPlayButtonItem: UIBarButtonItem!
    
    @IBAction func arpeggiatorPlayButtonItemAction(_ sender: UIBarButtonItem) {
        MTSignalPlayer.singleton.togglePlucking()
    }
    
    
    fileprivate let detailSegueName = "segueToTuningDetail"
    
    fileprivate let cellIdentifier = "TuningCell"
    fileprivate let entityName = "Tuning"
    fileprivate let sortKey = "tuningName"
    fileprivate var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    fileprivate var searchController: UISearchController!
    fileprivate var filteredTunings = [Tuning]()
    fileprivate var searchPredicate : NSPredicate?

    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: SEARCH AND FILTERS
    
    enum tuningFilter {
        case instruments
        case tuningtypes
        case all
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.tableView.isEditing = editing
        if let splitVc = self.splitViewController {
            if splitVc.viewControllers.count == 1 {
                arpeggiatorPlayButtonItem.isEnabled = !editing
            }
        }
        super.setEditing(editing, animated: animated)
    }
    
    public var currentFilter : tuningFilter = .all
    public var currentFilterKey : String?
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = self.searchController?.searchBar.text
        if let searchText = searchText {
            searchPredicate = searchText.isEmpty ? nil : NSPredicate(format: "tuningName contains[c] %@", searchText)
        } else { searchPredicate = nil }
        self.tableView.reloadData()
    }

    // MARK: Actions
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        setEditing(false, animated: true)
//        if segue.identifier == detailSegueName {
//            let tuningVc = segue.destination as! TuningDetailsViewController
//            tuningVc.configureWithTuning(sender as! Tuning)
//        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles
    }
    
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering() {
            return 1
        } else {
            return fetchedResultsController.sections!.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredTunings.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! TuningTableViewCell
        cell.delegate = self
        let tuning = tuningSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        cell.configure(withTuning: tuning, andPresenterVc:self, atIndexPath: indexPath)
        
        if let lastIndex = lastSelectedCellIndex {
            if lastIndex == indexPath {
                if !cell.isSelected {
                    cell.isSelected = true
                    
                }
            }
//            else if cell.isSelected {
//                cell.isSelected = false
//            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let tuning = tuningSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        return !(tuning.tuningName == CoreDataStack.standardTuningName && tuning.tuningNotes == CoreDataStack.standardTuningNotes)
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        lastSelectedCellIndex = indexPath
        let tuningTableViewCell = tableView.cellForRow(at: indexPath) as! TuningTableViewCell
        if MTSignalPlayer.singleton.currentTuning == tuningTableViewCell.targetTuning {
            MTSignalPlayer.singleton.togglePlucking()
        } else {
            MTSignalPlayer.singleton.currentTuning = tuningTableViewCell.targetTuning!
            if MTSignalPlayer.singleton.theArpeggiatorPlayState == .stopped {
                MTSignalPlayer.singleton.startPlucking()
            }
        }
        lastSelectedCellIndex = indexPath
        // tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        MTSignalPlayer.singleton.currentTuning = tuningSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        self.performSegue(withIdentifier: detailSegueName, sender: self)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let tuning = tuningSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            CoreDataStack.singleton.deleteTuningInPersistentStore(tuning)
            self.refetchData()
        }
        deleteAction.backgroundColor = UIColor.red
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            self.renameTuning(tuning)
            self.tableView.reloadData()
        }
        
        return [deleteAction, renameAction]
    }
    
    // MARK: Datasource
    
    func renameTuning(_ tuning:Tuning) {
        let alert = UIAlertController(title: "Rename Tuning", message: "Type a new name for \(tuning.tuningName!):", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = tuning.tuningName
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            tuning.tuningName = textField?.text
            CoreDataStack.singleton.saveContext()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Datasource
    
    func tuningSectionForRowAtIndexPath(_ indexPath: IndexPath, WithTableView tableView: UITableView) -> Tuning {
        if isFiltering() {
            return filteredTunings[indexPath.row]
        } else {
            return self.fetchedResultsController.object(at: indexPath) as! Tuning
        }
    }
    
    func refetchData() {
        var predicate : NSPredicate? = nil
        switch (self.currentFilter) {
        case .tuningtypes:
            predicate = NSPredicate(format: "SELF.tuningType.tuningTypeName = %@", currentFilterKey!)
        case .instruments:
            predicate = NSPredicate(format: "SELF.tuningInstrument.instrumentName = %@", currentFilterKey!)
        default: break
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            debugPrint("Error executing the fetch request: \(error)")
        }
    }
    
    
    // MARK: View Controller Lifecycle
    
    func addObservers() {
        if let splitVc = self.splitViewController {
            if splitVc.viewControllers.count == 1 {
                NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStart, object: nil, queue: nil) { (note) in
                    self.arpeggiatorPlayButtonItem.image = UIImage(named:"PauseIcon")
                }
                NotificationCenter.default.addObserver(forName: .mt_arpeggiatorDidStop, object: nil, queue: nil) { (note) in
                    self.arpeggiatorPlayButtonItem.image = UIImage(named:"PlayIcon")
                }
            }
        }
        NotificationCenter.default.addObserver(forName: .mt_coredata_shallUpdate, object: nil, queue: nil) { (note) in
            StuffLogger.print("updating searchtunings notif")
            self.refetchData()
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStart, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_arpeggiatorDidStop, object: nil)
        NotificationCenter.default.removeObserver(self, name: .mt_coredata_shallUpdate, object: nil)
    }
    
    deinit {
        removeObservers()
    }
    
    override func viewDidLoad() {
        if let splitVc = self.splitViewController {
            if splitVc.viewControllers.count > 1 {
                self.navigationItem.rightBarButtonItem = self.editButtonItem
//                self.navigationItem.leftBarButtonItem = splitVc.displayModeButtonItem;
            } else {
                self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
            }
        } else {
            self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.fetchBatchSize = 20
        let keySort = NSSortDescriptor(key: sortKey, ascending: true)
        fetchRequest.sortDescriptors = [keySort]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                   managedObjectContext: CoreDataStack.singleton.context,
                                                                   sectionNameKeyPath: nil,
                                                                   cacheName: nil)
        self.fetchedResultsController.delegate = self
        self.refetchData()
        addSearchBar()
        addObservers()
    }
    
    func addSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search All Tunings"
//        navigationItem.searchController = searchController
        self.tableView.tableHeaderView = searchController?.searchBar
//        self.tableView.delegate = self
        
        /**
 
         By setting definesPresentationContext on your view controller to true,
         you ensure that the search bar does not remain on the screen
         if the user navigates to another view controller
         while the UISearchController is active
         
         */
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let lastIndex = lastSelectedCellIndex {
        tableView.scrollToRow(at: lastIndex, at: .top, animated: true)
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        currentFilter = .all
        currentFilterKey = nil
        MTSignalPlayer.singleton.stopPlucking()
    }
    
}


// MARK: - NSFetchedResultsControllerDelegate

extension SearchTuningsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            var cell = tableView.cellForRow(at: indexPath!) as? TuningTableViewCell
            if (cell == nil) {
                cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath!) as? TuningTableViewCell
            }
            let tuning = fetchedResultsController.object(at: indexPath!) as! Tuning
            cell!.configure(withTuning: tuning, andPresenterVc:self, atIndexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
        
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        lastSelectedCellIndex = fetchedResultsController.indexPath(forObject: MTSignalPlayer.singleton.currentTuning)
        updateSearchResults(for: searchController)
    }
    
}


// MARK: - UISearchControllerDelegate

extension SearchTuningsViewController: UISearchControllerDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
        tableView.reloadData()
    }
    
}


// MARK: - UISearchResultsUpdating

extension SearchTuningsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        if searchBarIsEmpty() {
            searchPredicate = nil
            fetchedResultsController.fetchRequest.predicate = nil
        } else {
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let strippedString = searchController.searchBar.text?.trimmingCharacters(in: whitespaceCharacterSet) ?? ""
            
            let searchResults = self.fetchedResultsController.fetchedObjects as! [Tuning]
            
            switch (self.currentFilter) {
            case .all:
                searchPredicate = NSPredicate(format: "SELF.tuningName contains[c] %@", strippedString)
            case .tuningtypes:
                searchPredicate = NSPredicate(format: "SELF.tuningName contains[c] %@ AND SELF.tuningType.tuningTypeName = %@", strippedString, currentFilterKey!)
            case .instruments:
                searchPredicate = NSPredicate(format: "SELF.tuningName contains[c] %@ AND SELF.tuningInstrument.instrumentName = %@", strippedString, currentFilterKey!)
            }
            let filteredResults = searchResults.filter { searchPredicate!.evaluate(with: $0) }
            //        let searchResultsController = searchController.searchResultsController as! TuningsSearchResultsController
            //        searchResultsController.filteredTunings = filteredResults
            self.filteredTunings = filteredResults
        }
        switch (self.currentFilter) {
        case .all:
            searchController.searchBar.placeholder = "Search All Tunings"
        case .tuningtypes:
            searchController.searchBar.placeholder = "\(currentFilterKey!) Tunings"
        case .instruments:
            searchController.searchBar.placeholder = "\(currentFilterKey!) Tunings"
        }

        self.tableView.reloadData()
    }

    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }

    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}
