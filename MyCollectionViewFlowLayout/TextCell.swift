//
//  CollectionViewCell.swift
//  MyCollectionViewFlowLayout
//
//  Created by minse on 2017/6/5.
//  Copyright © 2017年 China. All rights reserved.
//

import UIKit

class TextCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        textLabel.backgroundColor = UIColor.hexString("eeeeee")
        textLabel.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.layer.cornerRadius = self.frame.height/2
    }
}
