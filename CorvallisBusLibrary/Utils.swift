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
    
    /**
        Returns the first element in self that satisfies the given predicate,
        or the first element in the sequence if no predicate is provided.
    */
    func first(predicate: T -> Bool = { t in true }) -> T? {
        for element in self {
            if predicate(element) {
                return element
            }
        }
        return nil
    }
    
    /**
        Takes a transform that returns an optional type and
        returns an array containing only the non-nil elements.
    */
    func mapUnwrap<U>(transform: T -> U?) -> [U] {
        var result = [U]()
        
        for t in self {
            if let u = transform(t) {
                result.append(u)
            }
        }
        return result
    }
    
    /**
        Takes an equality comparer and returns a new array containing all the distinct elemnts.
    */
    func distinct(comparer: (T, T) -> Bool) -> [T] {
        var result = [T]()
        for t in self {
            // if there are no elements in the result set equal to this element, add it
            if !result.any({ comparer($0, t) }) {
                result.append(t)
            }
        }
        return result
    }
}