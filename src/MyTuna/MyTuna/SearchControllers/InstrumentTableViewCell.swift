//
//  InstrumentTableViewCell.swift
//  MyTuna
//
//  Created by Luca Cipressi on 03/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

class InstrumentTableViewCell: UITableViewCell {

    @IBOutlet weak var instrumentNameLabel: UILabel!
    @IBOutlet weak var instrumentCountLabel: BadgeableLabel!
    
    func configureWithInstrument(_ instro:Instrument) {
        instrumentNameLabel.text = instro.instrumentName
        instrumentCountLabel.text = String(instro.instrumentTunings!.count)
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        instrumentNameLabel.textColor = selected ? UIColor.black : UIColor.white
    }

}
