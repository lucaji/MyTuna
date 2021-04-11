//
//  MTTuningProxy.swift
//  MyTuna
//
//  Created by Luca Cipressi on 12/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

class MTTuningProxy: NSObject {

    public var tuningName : String! = CoreDataStack.standardTuningName
    public var tuningInstrumentName : String! = CoreDataStack.standardTuningInstrumentName
    public var tuningTypeName : String! = CoreDataStack.standardTuningTuningTypeName
    public var tuningNotes = CoreDataStack.standardTuningNotes.toPitchedNotes()
    public var tuningComments : String? = CoreDataStack.standardTuningComment
    
    var tuningNotesString : String {
        let noteNames = tuningNotes.compactMap({ (note) -> String? in
            return note.string
        })
        return noteNames.joined(separator: "-")
    }
    
    override init() {
        
    }
    
    init(withTuning tuning:Tuning) {
        tuningName = tuning.tuningName!
        tuningInstrumentName = tuning.tuningInstrument!.instrumentName!
        tuningTypeName = tuning.tuningType!.tuningTypeName!
        tuningNotes = tuning.tuningNotes!.toPitchedNotes()
        tuningComments = tuning.tuningComments
    }
    
    init?(withDictionary dictionary:[String : String]) {
        for key in CoreDataStack.csvColumns {
            if let _ = dictionary[key] { } else {
                StuffLogger.print("csv does not contain key \(key).")
                return nil
            }
        }
        
        // Check for valid notes first
        let tuningNotesString = dictionary[CoreDataStack.csvColumns[3]]!
        let cleanedNotes = tuningNotesString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedNotes.count > 0 && cleanedNotes.count < 255 {
            let n = cleanedNotes.toPitchedNotes()
            if n.count < 1 || n.count > CoreDataStack.maxTuningNotesAccepted {
                StuffLogger.print("maxTuningNotesAccepted exceeded for \(String(describing: tuningName)) with \(String(describing: tuningNotes)).")
                return nil
            }
            tuningName = String(dictionary[CoreDataStack.csvColumns[0]]!.prefix(CoreDataStack.nameMaxAcceptedLength))
            if (tuningName.count == 0) {
                StuffLogger.print("tuningName zero length for \(String(describing: tuningName)) with \(String(describing: tuningNotes)).")
                return nil
            }
            tuningInstrumentName = String(dictionary[CoreDataStack.csvColumns[1]]!.prefix(CoreDataStack.nameMaxAcceptedLength))
            if (tuningInstrumentName.count == 0) {
                StuffLogger.print("tuningInstrumentName zero length for \(String(describing: tuningName)) with \(String(describing: tuningNotes)).")
                return nil
            }
            tuningTypeName = String(dictionary[CoreDataStack.csvColumns[2]]!.prefix(CoreDataStack.nameMaxAcceptedLength))
            if (tuningTypeName.count == 0) {
                StuffLogger.print("tuningTypeName zero length for \(String(describing: tuningName)) with \(String(describing: tuningNotes)).")
                return nil
            }
            tuningNotes = n
            tuningComments = dictionary[CoreDataStack.csvColumns[4]]
        } else {
            return nil
        }
    }
    
}



extension Tuning {
    func toTuningProxy() -> MTTuningProxy {
        return MTTuningProxy(withTuning:self)
    }
}
