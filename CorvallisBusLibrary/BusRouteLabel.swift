//
//  BusRouteLabel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/5/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

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
