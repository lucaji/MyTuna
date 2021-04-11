//
//  TuningsTableViewCell.swift
//  MyTuna
//
//  Created by Luca Cipressi on 24/12/2017.
//  Copyright (c) 2017 Luca Cipressi - lucaji.github.io - lucaji@mail.ru. All rights reserved.
//

import UIKit

protocol TuningTableViewCellDelegate : class {
    //    func tuningTablePlayButtonAction(tuningTableViewCell:TuningTableViewCell)
    func tuningSegmentedControlAction(withPitchedNote note:MTPitchedNote, andAnchorView anchor:MTTuningSegmentControl)
}

class TuningTableViewCell: UITableViewCell {

    public weak var delegate : TuningTableViewCellDelegate?
    
    @IBOutlet weak var tuningTitleLabel: UILabel!
    
    @IBOutlet weak var tuningSegmentedControl: MTTuningSegmentControl!
    @IBOutlet weak var tuningDateLabel: UILabel!
    @IBOutlet weak var tuningRightLabel: UILabel!
    
    weak var targetTuning : Tuning?
    var tuningCellIndexPath : IndexPath?
    
//    @IBAction func PlayTuningButtonAction(_ sender: Any) {
//        self.delegate?.tuningTablePlayButtonAction(tuningTableViewCell: self)
//    }
    
    func configure(withTuning tuning : Tuning, andPresenterVc presenterVc:BaseViewController, atIndexPath indexPath:IndexPath) {
        targetTuning = tuning
        self.tuningCellIndexPath = indexPath
        self.tuningTitleLabel.text = tuning.tuningName
        self.tuningDateLabel.text = tuning.tuningType?.tuningTypeName
        self.tuningRightLabel.text = tuning.tuningInstrument?.instrumentName
        tuningSegmentedControl.mt_configure(withTuning: tuning, andPresentingViewController: presenterVc)
        self.tuningSegmentedControl.isSelected = false
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        tuningTitleLabel.textColor = selected ? UIColor.black : UIColor.white
        tuningDateLabel.textColor = selected ? UIColor.black : UIColor.white
        tuningRightLabel.textColor = selected ? UIColor.black : UIColor.white
    
        tuningSegmentedControl.tintColor = selected ? UIColor.black : UIColor.lightGray
    }
    

}
