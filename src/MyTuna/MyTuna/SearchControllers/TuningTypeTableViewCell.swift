//
//  TuningTypeTableViewCell.swift
//  MyTuna
//
//  Created by Luca Cipressi on 03/01/2018.
//  Copyright (c) 2017-2021 Luca Cipressi - lucaji.github.io - lucaji@mail.ru . All rights reserved.
//

import UIKit

class TuningTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var tuningTypeNameLabel: UILabel!
    @IBOutlet weak var tuningTypeTuningsCountLabel: BadgeableLabel!
    
    func configureWithTuningType(_ tuningType:TuningType) {
        tuningTypeNameLabel.text = tuningType.tuningTypeName
        tuningTypeTuningsCountLabel.text = String(tuningType.tunings?.count ?? 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        tuningTypeNameLabel.textColor = selected ? UIColor.black : UIColor.white

    }

}
