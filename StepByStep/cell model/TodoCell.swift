//
//  RoutineCell.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/08.
//

import Foundation
import UIKit

class TodoCell: UITableViewCell {

    
    @IBOutlet var label: UILabel!
    @IBOutlet var TodoItemNameLabel: UILabel!
    @IBOutlet var TodoItemDiscLabel: UILabel!
    @IBOutlet var TodoTimeLabel: UILabel!
    @IBOutlet var deleteItemBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        print("delete? 미구현?")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
