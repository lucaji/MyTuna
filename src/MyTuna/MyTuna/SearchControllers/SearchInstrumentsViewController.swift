//
//  SearchInstrumentsViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 26/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit
import CoreData

class SearchInstrumentsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    fileprivate let detailSegueName = "segueInstrumentsToTunings"
    
    fileprivate let cellIdentifier : String = "InstrumentCell"
    fileprivate let entityName = "Instrument"
    fileprivate let sortKey = "instrumentName"
    fileprivate var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    fileprivate var searchController: UISearchController!
    fileprivate var filteredInstruments = [Instrument]()
    fileprivate var searchPredicate : NSPredicate?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        self.tableView.isEditing = editing
        super.setEditing(editing, animated: animated)
    }

    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = self.searchController?.searchBar.text
        if let searchText = searchText {
            searchPredicate = searchText.isEmpty ? nil : NSPredicate(format: "instrumentName contains[c] %@", searchText)
        } else { searchPredicate = nil }
        self.tableView.reloadData()
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
            return filteredInstruments.count
        } else {
            let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! InstrumentTableViewCell
        let instro = instrumentSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        cell.configureWithInstrument(instro)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let instro = instrumentSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
//        self.title = instro.instrumentName
        self.performSegue(withIdentifier: detailSegueName, sender: instro)
        //        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let instro = instrumentSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        self.performSegue(withIdentifier: detailSegueName, sender: instro)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let instro = instrumentSectionForRowAtIndexPath(indexPath, WithTableView: tableView)
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            CoreDataStack.singleton.deleteInstrument(instro)
            self.tableView.reloadData()
        }
        deleteAction.backgroundColor = UIColor.red
        
        let renameAction = UITableViewRowAction(style: .normal, title: "Rename") { action, index in
            self.renameInstrument(instro)
            self.tableView.reloadData()
        }
        
        return [deleteAction, renameAction]
    }
    
    
    @objc func addButtonAction() {
        addInstrumentAlert { (instro) in
            
        }

    }

    // MARK: Datasource
    
    
    func instrumentSectionForRowAtIndexPath(_ indexPath: IndexPath, WithTableView tableView: UITableView) -> Instrument {
        if isFiltering() {
            return filteredInstruments[indexPath.row]
        } else {
            return self.fetchedResultsController.object(at: indexPath) as! Instrument
        }
    }
    
    func refetchData() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            debugPrint("Error executing the fetch request: \(error)")
        }
    }
    
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if let splitVc = self.splitViewController {
//            if splitVc.viewControllers.count > 0 {
//                self.navigationItem.leftBarButtonItem = splitVc.displayModeButtonItem;
//            }
//        }

        let addButton = UIBarButtonItem(image: UIImage(named:"NewItemIcon"), style: .plain, target: self, action: #selector(addButtonAction))
        navigationItem.leftBarButtonItem = addButton
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        NotificationCenter.default.addObserver(forName: .mt_coredata_shallUpdate, object: nil, queue: nil) { (note) in
            StuffLogger.print("updating searchinstruments notif")
            self.refetchData()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
    }

    
    func addSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search Instruments"
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

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .mt_coredata_shallUpdate, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        refetchData()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == detailSegueName {
            let tuningVc = segue.destination as! SearchTuningsViewController
            let instro = sender as! Instrument
            tuningVc.currentFilterKey = instro.instrumentName
            tuningVc.currentFilter = .instruments
        }
    }
    
    
}

// MARK: - NSFetchedResultsControllerDelegate

extension SearchInstrumentsViewController: NSFetchedResultsControllerDelegate {
    
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
            var cell = tableView.cellForRow(at: indexPath!) as? InstrumentTableViewCell
            if (cell == nil) {
                cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath!) as? InstrumentTableViewCell
            }
            let instro = fetchedResultsController.object(at: indexPath!) as? Instrument
            if (instro != nil && cell != nil) {
                cell!.configureWithInstrument(instro!)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        tableView.reloadData()
    }
    
}


// MARK: - UISearchControllerDelegate

extension SearchInstrumentsViewController: UISearchControllerDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
        tableView.reloadData()
    }
    
}

// MARK: - UISearchResultsUpdating

extension SearchInstrumentsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if searchBarIsEmpty() {
            searchPredicate = nil
        } else {
            
            let whitespaceCharacterSet = CharacterSet.whitespaces
            let strippedString = searchController.searchBar.text?.trimmingCharacters(in: whitespaceCharacterSet) ?? ""
            
            let searchResults = self.fetchedResultsController.fetchedObjects as! [Instrument]
            searchPredicate = NSPredicate(format: "SELF.instrumentName contains[c] %@", strippedString)
            let filteredResults = searchResults.filter { searchPredicate!.evaluate(with: $0) }
            filteredInstruments = filteredResults
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

