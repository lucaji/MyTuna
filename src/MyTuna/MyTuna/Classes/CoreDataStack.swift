//
//  CoreDataStack.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let singleton : CoreDataStack = CoreDataStack()
    public static let maxTuningNotesAccepted = 7

    var context:NSManagedObjectContext
    var psc:NSPersistentStoreCoordinator
    var model:NSManagedObjectModel
    var store:NSPersistentStore?
    
    init() {
        let bundle = Bundle.main
        let modelURL =
        bundle.url(forResource: "MyTuna", withExtension:"momd")
        model = NSManagedObjectModel(contentsOf: modelURL!)!
        
        psc = NSPersistentStoreCoordinator(managedObjectModel:model)
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        
        let documentsURL = self.applicationDocumentsDirectory
        let storeURL = documentsURL.appendingPathComponent("MyTuna.sqlite")
        
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try store = psc.addPersistentStore(ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options)
        } catch {
            debugPrint("Error adding persistent store: \(error)")
            abort()
        }
        
    }
    
    fileprivate func postUpdateNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mt_coredata_shallUpdate, object: nil, userInfo: nil)
        }
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                postUpdateNotification()
            }
            catch {
                debugPrint("Could not save: \(error)")
            }
        }
    }
    
    
    lazy var applicationDocumentsDirectory: URL = {
        let doucumentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let _directoryURL = doucumentURL.appendingPathComponent("Voice")
        do {
            try FileManager.default.createDirectory(at: _directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Error creating directory: \(error)")
        }
        return _directoryURL
    }()

    // MARK: Repository
    
    func deleteVoiceInPersistentStore(_ voice: Voice) {
        let removeFileURL = applicationDocumentsDirectory.appendingPathComponent(voice.voiceFilename!)
        _ = try? FileManager.default.removeItem(at: removeFileURL)
        self.context.delete(voice)
        self.saveContext()
    }
    
    
    func deleteSignalInPersistentStore(_ signal: SignalEvent) {
        self.context.delete(signal)
        self.saveContext()
    }

    func deleteTuningInPersistentStore(_ tuning: Tuning) {
        self.context.delete(tuning)
        MTSignalPlayer.singleton.currentTuning = myStandardGuitarTuningEntity()
        self.saveContext()
    }
    
    
    func deleteInstrument(_ instrument:Instrument) {
        self.context.delete(instrument)
        MTSignalPlayer.singleton.currentTuning = myStandardGuitarTuningEntity()
        self.saveContext()
    }
    
    func deleteTuningType(_ tuningType:TuningType) {
        self.context.delete(tuningType)
        MTSignalPlayer.singleton.currentTuning = myStandardGuitarTuningEntity()
        self.saveContext()
    }
    
    func deleteAllEntities(withName name:String) -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest)
        do {
            try self.context.execute(deleteRequest)
            postUpdateNotification()
        } catch let error as NSError {
            print(error.description)
            return false
        }
        return true
    }
    
    func alphabeticSectionIndex() -> [String]
    {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tuning")
        var results : [Tuning]
        do {
            results = try self.context.fetch(fetchRequest) as! [Tuning]
        } catch {
            return []
        }
        var initials : [String] = []
        for tuning in results {
            let tuningInitial = String(describing: tuning.tuningName?.first)
            if !initials.contains(tuningInitial) {
                initials.append(tuningInitial)
            }
        }
        return initials
    }
    
    func allTuningTypes() -> [TuningType] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TuningType")
        var results: [TuningType] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [TuningType]
        } catch {
            print("error executing fetch request: \(error)")
        }
        return results
    }
    
    func allInstruments() -> [Instrument] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Instrument")
        var results: [Instrument] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [Instrument]
        } catch {
            print("error executing fetch request: \(error)")
        }
        return results
    }

    
    func tuningTypeIfExistent(withTitle ttype:String, withDescription description:String?) -> TuningType! {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TuningType")
        fetchRequest.predicate = NSPredicate(format: "tuningTypeName = %@", ttype)
        var results: [TuningType] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [TuningType]
        } catch {
            print("error executing fetch request: \(error)")
            return nil
        }
        
        if results.count > 0 {
            return results.first
        }
        let tuningTypeEntity = NSEntityDescription.entity(forEntityName: "TuningType", in: self.context)
        let tuningType = TuningType(entity: tuningTypeEntity!, insertInto: self.context)
        tuningType.tuningTypeName = ttype
        tuningType.tuningTypeDescription = description
        return tuningType
    }
    
    func instrumentIfExistent(withName iname:String) -> Instrument! {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Instrument")
        fetchRequest.predicate = NSPredicate(format: "instrumentName = %@", iname)
        var results: [Instrument] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [Instrument]
        } catch {
            print("error executing fetch request: \(error)")
            return nil
        }
        
        if results.count > 0 {
            return results.first
        }
        let instroEntity = NSEntityDescription.entity(forEntityName: "Instrument", in: self.context)
        let instro = Instrument(entity: instroEntity!, insertInto: self.context)
        instro.instrumentName = iname
        return instro
    }
    
    func tuningIfExistent(withName tname:String) -> Tuning? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tuning")
        fetchRequest.predicate = NSPredicate(format: "tuningName = %@", tname)
        var results: [Tuning] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [Tuning]
        } catch {
            print("error executing fetch request: \(error)")
            return nil
        }
        
        if results.count > 0 {
            return results.first
        }
        return nil
    }
    
    // MARK: Standard Tuning
    
    static let standardTuningName = "Standard Guitar Tuning"
    static let standardTuningInstrumentName = "Guitar"
    static let standardTuningTuningTypeName = "Standard"
    static let standardTuningNotes = "E2-A2-D3-G3-B3-E4"
    static let standardTuningComment = "The default guitar tuning."
    
    func myStandardGuitarTuningEntity() -> Tuning {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tuning")
        fetchRequest.predicate = NSPredicate(format: "tuningNotes = %@", CoreDataStack.standardTuningNotes)
        var tuning : Tuning? = nil
        var results: [Tuning] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [Tuning]
        } catch {
            print("error executing fetch request: \(error)")
        }
        tuning = results.first
        if tuning == nil {
            let tuningEntity = NSEntityDescription.entity(forEntityName: "Tuning", in: self.context)
            tuning = Tuning(entity: tuningEntity!, insertInto: self.context)
            tuning!.tuningName = CoreDataStack.standardTuningName
            tuning!.tuningInstrument = self.instrumentIfExistent(withName: CoreDataStack.standardTuningInstrumentName)
            tuning!.tuningType = self.tuningTypeIfExistent(withTitle: CoreDataStack.standardTuningTuningTypeName, withDescription: nil)
            tuning!.tuningNotes = CoreDataStack.standardTuningNotes
            tuning!.tuningComments = CoreDataStack.standardTuningComment
        }
        return tuning!
    }
    
    // MARK: Import Csv
    
    func importCsv(fromUrl url:URL) -> Bool {
        var content : String
        do {
            try content = String(contentsOfFile: url.path, encoding: .utf8)
        } catch {
            StuffLogger.print("Could not read file \(url.path)")
            return false
        }
        let tuningImportLogString = tunercsv(data: content)
        NotificationCenter.default.post(name: .mt_coredata_importedCsv, object: nil, userInfo: [LJK.NotificationKeys.coreDataImportedCsvObjectKey: String(tuningImportLogString)])
        return true
    }
    
    // MARK: Export csv
    
    func exportAllTunings(withPresenterVc presenterVc:BaseViewController, withBarButton barButton:UIBarButtonItem?) -> URL? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tuning")
        var results: [Tuning] = []
        do {
            results = try self.context.fetch(fetchRequest) as! [Tuning]
        } catch {
            print("error executing fetch request: \(error)")
            return nil
        }
        return exportCsv(selectedTunings: results, withPresenterVc: presenterVc, withBarButton: barButton)
    }
    
    let separator = ";"
    func exportCsv(selectedTunings tuningList:[Tuning], withPresenterVc presenterVc:BaseViewController, withBarButton barButton:UIBarButtonItem?) -> URL? {
        let fileName = "mytuna_tunings.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let columns = CoreDataStack.csvColumns.joined(separator: separator)
        var csvText = columns + "\n"
        
        let count = tuningList.count
        if count > 0 {
            
            for tuning in tuningList {
                
//                let dateFormatter = NSDateFormatter()
//                dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
//                let convertedDate = dateFormatter.stringFromDate(fillup.date)
                
                let newLine = "\"\(tuning.tuningName!)\"\(separator)\"\(tuning.tuningInstrument!.instrumentName!)\"\(separator)\"\(tuning.tuningType!.tuningTypeName!)\"\(separator)\"\(tuning.tuningNotes!)\"\(separator)\"\(tuning.tuningComments ?? "")\"\n"
                csvText.append(newLine)
            }
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file")
                print("\(error)")
                return nil
            }
            
        } else {
//            showErrorAlert("Error", msg: "There is no data to export")
        }
        return path
    }

    
    // MARK: Restore defaults and Import
    
    func MTImportDefaultTunings() -> String {
        let fileString = readDataFromCSV(fileName: "mytunaguitartunings", fileType: "csv")
        let importLogString = tunercsv(data: fileString!)
        return importLogString
    }
    
    fileprivate func readDataFromCSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            //contents = cleanRows(file: contents)
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    fileprivate static func sanitizeString(theString:String)->String{
        let chars: [String] = ["\t", ">", "<", "#", "&", "+", "$", "\\", "|", "="]
        var clen = theString
        for char in chars {
            clen = clen.replacingOccurrences(of: char, with: "")
        }
        clen = clen.replacingOccurrences(of: "  ", with: " ")
        clen = clen.replacingOccurrences(of: " ,", with: ", ")
        clen = clen.replacingOccurrences(of: " .", with: ". ")
        return clen
    }
    
    static let nameMaxAcceptedLength = 64
    static let csvColumns = ["tuningName", "tuningInstrument", "tuningType", "tuningNotes", "tuningComments"]

    fileprivate func tunercsv(data: String) -> String {
        let csv = CSV(string: data, delimiter:";")
        var count = 0
        var restored = 0
        var added = 0
        csv.enumerateAsDict { dict in

            if let tuningProxy = MTTuningProxy(withDictionary:dict) {
                let tuningName = tuningProxy.tuningName
                var tuning = self.tuningIfExistent(withName: tuningName!)
                if (tuning == nil) {
                    let tuningEntity = NSEntityDescription.entity(forEntityName: "Tuning", in: CoreDataStack.singleton.context)
                    tuning = Tuning(entity: tuningEntity!, insertInto: self.context)
                    tuning!.tuningName = tuningProxy.tuningName
                    added += 1
                } else {
                    restored += 1
                }
                tuning!.tuningInstrument = self.instrumentIfExistent(withName: tuningProxy.tuningInstrumentName)
                tuning!.tuningType = self.tuningTypeIfExistent(withTitle: tuningProxy.tuningTypeName, withDescription: nil)
                tuning!.tuningNotes = tuningProxy.tuningNotesString
                tuning!.tuningComments = tuningProxy.tuningComments
            }

            count += 1
        }
        let logString = "Tunings import finished:\rCreated: \(added).\rRestored: \(restored).\rParsed: \(count)."
        self.saveContext()
        return logString
    }

    func duplicateTuning(_ sourceTuning:Tuning) -> Tuning {
        let tuneEntity = NSEntityDescription.entity(forEntityName: "Tuning", in: self.context)
        let copytuning = Tuning(entity: tuneEntity!, insertInto: self.context)
        copytuning.tuningName = sourceTuning.tuningName! + " Copy"
        copytuning.tuningType = sourceTuning.tuningType
        copytuning.tuningInstrument = sourceTuning.tuningInstrument
        copytuning.tuningNotes = sourceTuning.tuningNotes
        copytuning.tuningComments = sourceTuning.tuningComments
        saveContext()
        return copytuning
    }
    
    
}

// already in swift 4.
//extension String {
//    var isBlank: Bool {
//        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//}
//extension Optional where Wrapped == String {
//    var isBlank: Bool {
//        if let unwrapped = self {
//            return unwrapped.isBlank
//        } else {
//            return true
//        }
//    }
//}

