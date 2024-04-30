//
//  QuestionTableViewCell.swift
//  StepByStep
//
//  Created by 엄현호 on 2023/05/09.
//

import UIKit
// MARK: - QuestionTableViewCell
protocol QuestionTableViewCellDelegate: AnyObject {
    func didSelectAnswer(_ answerIndex: Int, at indexPath: IndexPath)
}

class QuestionTableViewCell: UITableViewCell {
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var answerSegmentedControl: UISegmentedControl!
    @IBOutlet weak var answerLabel: UILabel!

    weak var delegate: QuestionTableViewCellDelegate?
    var indexPath: IndexPath!
    
    @IBAction func answerSelected(_ sender: UISegmentedControl) {
        delegate?.didSelectAnswer(sender.selectedSegmentIndex, at: indexPath)
    }
}
