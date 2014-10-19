//
//  Utils.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/18/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

extension Array {
    /**
        Indicates whether there are any elements in self that satisfy the predicate.
        If no predicate is supplied, indicates whether there are any elements in self.
    */
    func any(predicate: T -> Bool = { t in true }) -> Bool {
        for element in self {
            if predicate(element) {
                return true
            }
        }
        return false
    }
}