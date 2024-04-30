//
//  ChallangeCell.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/23.
//

import UIKit

protocol ChallangeCellDelegate: AnyObject {
    func didTapDeleteButton(in cell: ChallangeCell)
}

class ChallangeCell: UITableViewCell {
    weak var delegate: ChallangeCellDelegate?

    @IBOutlet weak var Goalbtn: UIButton!
    @IBOutlet weak var GoalLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func goalbtn(_ sender: UIButton) {
        delegate?.didTapDeleteButton(in: self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
