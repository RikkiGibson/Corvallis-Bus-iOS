//
//  BusRouteLabel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/5/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class BusRouteLabel: UILabel {
    
    /// Overrides background color so that the system doesn't force it transparent when selecting a cell.
    /// Don't use this to set the background color. Use backgroundColorActual.
    override var backgroundColor: UIColor? {
        get {
            return super.backgroundColor
        }
        set(value) {
            
        }
    }
    
    /**
    This property actually sets the background color.
    */
    var backgroundColorActual: UIColor? {
        get {
            return super.backgroundColor
        }
        set(value) {
            super.backgroundColor = value
        }
    }
}
