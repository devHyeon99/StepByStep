//
//  testCell.swift
//  StepByStep
//
//  Created by Yune gim on 2023/05/02.
//

import UIKit

class testCell: UITableViewCell {

    @IBOutlet var insideBox: UIView!
    @IBOutlet var delCehckBox: CheckBox!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var discLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        delCehckBox.isChecked = false
        delCehckBox.isHidden = true
        // Initialization code
        insideBox.layer.cornerRadius = 10
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()

    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
