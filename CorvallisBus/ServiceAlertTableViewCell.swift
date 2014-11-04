//
//  ServiceAlertTableViewCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/4/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class ServiceAlertTableViewCell: UITableViewCell {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
