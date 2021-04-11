//
//  SignalTableViewCell.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

class SignalTableViewCell: UITableViewCell {

    @IBOutlet weak var signalNameLabel: UILabel!
    @IBOutlet weak var signalDetailLabel: UILabel!
    @IBOutlet weak var signalRightDetailLabel: UILabel!
    
    func configure(withSignal signal : SignalEvent) {
        self.signalNameLabel.text = signal.signalName
        self.signalDetailLabel.text = signal.signalFrequency?.stringValue
        self.signalRightDetailLabel.text = signal.signalType?.stringValue
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
