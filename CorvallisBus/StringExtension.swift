//
//  StringExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

extension String {
    func toDouble() -> Double? {
        let possibleNumber = NSNumberFormatter().numberFromString(self)
        if let value = possibleNumber {
            return .Some(value.doubleValue)
        }
        else {
            return .None
        }
    }
    
    func toBool() -> Bool? {
        switch (self.lowercaseString) {
        case "true": return .Some(true)
        case "false": return .Some(false)
        default: return .None
        }
    }
}