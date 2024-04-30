//
//  RoutineCell.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/08.
//

import Foundation

import UIKit

class RoutineCell: UITableViewCell {

    
    @IBOutlet var label: UILabel!
    @IBOutlet var routineItemNameLabel: UILabel!
    @IBOutlet var routineItemDiscLabel: UILabel!
    @IBOutlet var routineTimeLabel: UILabel!
    
    @IBOutlet var deleteItemBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    

}
