//
//  LogTableViewCell.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 13.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit

let kReuseCellIdentifier = "LogTableViewCellReuseIdentifier"

class LogTableViewCell: UITableViewCell {

    @IBOutlet weak var labelUahUsd: UILabel!
    @IBOutlet weak var labelUahEur: UILabel!
    @IBOutlet weak var labelRubUsd: UILabel!
    @IBOutlet weak var labelRubEur: UILabel!
    @IBOutlet weak var labelUsdOil: UILabel!
    
    // MARK: - Overridden methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
