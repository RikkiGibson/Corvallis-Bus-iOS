//
//  BusRouteDetailCell.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class BusRouteDetailCell: UITableViewCell {
    
    @IBOutlet weak var labelRouteName: BusRouteLabel!
    
    @IBOutlet weak var labelEstimate: UILabel!
    
    @IBOutlet weak var labelSchedule: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.labelRouteName.layer.cornerRadius = 5
        self.labelRouteName.clipsToBounds = true
        self.labelRouteName.layoutMargins = UIEdgeInsets(top: 20, left: 30, bottom: 20, right: 30)
        // Initialization code
    }
}

class BusRouteLabel: UILabel {
    private var canChangeBackgroundColor = false
    
    override var backgroundColor: UIColor? {
        get {
            return super.backgroundColor
        }
        set(value) {
            if self.canChangeBackgroundColor {
                super.backgroundColor = value
            }
        }
    }
    
    /**
        This property actually sets the background color.
    */
    var backgroundColorActual: UIColor? {
        get {
            return self.backgroundColor
        }
        set(value) {
            self.canChangeBackgroundColor = true
            self.backgroundColor = value
            self.canChangeBackgroundColor = false
        }
    }
}