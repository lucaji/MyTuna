//
//  VoiceSearchResultsController.swift
//  VoiceMemos
//
//  Created by Zhouqi Mo on 2/23/15.
//  Copyright (c) 2015 Zhouqi Mo. All rights reserved.
//

import UIKit

class VoiceSearchResultsController: UITableViewController {
    
    // MARK: Property
    var filteredVoices = [Voice]()
}

class TuningsSearchResultsController: UIViewController {

    // MARK: Property
    var filteredTunings = [Tuning]()
    var filteredInstruments = [Instrument]()
    var filteredTuningTypes = [TuningType]()
}

class SignalsSearchResultsController: UITableViewController {
    
    // MARK: Property
    var filteredSignals = [SignalEvent]()
}
