//
//  SignalsTableViewController.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit
import CoreData

class SignalsTableViewController: UITableViewController, UISearchBarDelegate {

    var addingEntitySegueFlag : Bool = false
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>!
    var searchController: UISearchController!

    var resultsTableController: SignalsSearchResultsController!
    weak var selectedSignal: SignalEvent?

    
    func updateDataSource() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SignalEvent")
        fetchRequest.fetchBatchSize = 20
        let keySort = NSSortDescriptor(key: "signalTimestamp", ascending: false)
        
        fetchRequest.sortDescriptors = [keySort]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: CoreDataStack.singleton.context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            debugPrint("Error executing the fetch request: \(error)")
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        updateDataSource()
        addSearchBar()

    }

    
    func addSearchBar() {
        resultsTableController = SignalsSearchResultsController()
        
        resultsTableController.tableView.delegate = self
        resultsTableController.tableView.dataSource = self
        searchController = UISearchController(searchResultsController: resultsTableController)
        
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.delegate = self
        
        definesPresentationContext = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}




// MARK: - NSFetchedResultsControllerDelegate

extension SignalsTableViewController: NSFetchedResultsControllerDelegate {
    
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
            let cell = tableView.cellForRow(at: indexPath!) as! SignalTableViewCell
            let signal = fetchedResultsController.object(at: indexPath!) as! SignalEvent
            cell.configure(withSignal: signal)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateSearchResults(for: searchController)
    }
    
}


// MARK: - UISearchControllerDelegate

extension SignalsTableViewController: UISearchControllerDelegate {
    
    func willDismissSearchController(_ searchController: UISearchController) {
        tableView.reloadData()
    }
    
}

// MARK: - UISearchResultsUpdating

extension SignalsTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        var predicate : NSPredicate
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchController.searchBar.text?.trimmingCharacters(in: whitespaceCharacterSet) ?? ""
        
        let searchResults = self.fetchedResultsController.fetchedObjects as! [SignalEvent]
        predicate = NSPredicate(format:
            "SELF.signalName contains[c] %@", strippedString)
        let filteredResults = searchResults.filter { predicate.evaluate(with: $0) }
        
        let searchResultsController = searchController.searchResultsController as! SignalsSearchResultsController
        searchResultsController.filteredSignals = filteredResults
        searchResultsController.tableView.reloadData()
    }
    
}
