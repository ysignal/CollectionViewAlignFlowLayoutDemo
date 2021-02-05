//
//  TextCell.swift
//  CollectionViewFlowLayout
//
//  Created by user on 2021/2/5.
//

import UIKit

class TextCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel.backgroundColor = .hexString("eeeeee")
        textLabel.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.layer.cornerRadius = frame.height/2
    }
    
}
