//
//  TodayTableViewCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class FavoriteStopTableViewCell: UITableViewCell {
    @IBOutlet weak var labelRouteName: UILabel!
    @IBOutlet weak var labelArrivals: UILabel!
    @IBOutlet weak var labelDistance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .None
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
