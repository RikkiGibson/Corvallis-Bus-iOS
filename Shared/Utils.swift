//
//  Utils.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/18/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class Box<T> {
    let value: T
    init(value: T) {
        self.value = value
    }
}

func memoize<T, Key : Hashable, Value>(_ f: @escaping (T) -> Value, getHash: @escaping (T) -> Key) -> ((T) -> Value) {
    var memo = [Key : Value]()
    return {
        if memo[getHash($0)] == nil {
            memo[getHash($0)] = f($0)
        }
        return memo[getHash($0)]!
    }
}

func parseColor(_ obj: AnyObject?) -> Color? {
    if let colorString = obj as? String, colorString.count == 6 {
        var colorHex: UInt32 = 0
        Scanner(string: colorString).scanHexInt32(&colorHex)
        return Color(red: CGFloat(colorHex >> 16 & 0xFF) / 255.0,
            green: CGFloat(colorHex >> 8 & 0xFF) / 255.0,
            blue: CGFloat(colorHex & 0xFF) / 255.0, alpha: 1.0)
    } else {
        return nil
    }
}

/// Maps a function using the corresponding elements of two sequences.
func mapPairs<S: Sequence, T: Sequence, U>(_ seq1: S, seq2: T,
    transform: (S.Iterator.Element, T.Iterator.Element) -> U) -> [U] {
        var result = [U]()
        var generator1 = seq1.makeIterator()
        var generator2 = seq2.makeIterator()
        while let element1 = generator1.next() {
            if let element2 = generator2.next() {
                result.append(transform(element1, element2))
            } else {
                break
            }
        }
        return result
}

func mapAdjacentElements<S: Sequence, U>(_ seq: S,
    transform: (S.Iterator.Element, S.Iterator.Element) -> U) -> [U] {
        var result = [U]()
        var generator = seq.makeIterator()
        var prev = generator.next()
        while let current = generator.next(), prev != nil {
            result.append(transform(prev!, current))
            prev = current
        }
        return result
}

extension Set {
    func mapUnwrap<U>(_ transform: (Element) -> U?) -> Set<U> {
        var result = Set<U>()
        for t in self {
            if let u = transform(t) {
                result.insert(u)
            }
        }
        return result
    }
}

extension Array {
    /**
        Indicates whether there are any elements in self that satisfy the predicate.
        If no predicate is supplied, indicates whether there are any elements in self.
    */
    func any(_ predicate: (Element) -> Bool = { t in true }) -> Bool {
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
    func first(_ predicate: (Element) -> Bool = { t in true }) -> Element? {
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
    func mapUnwrap<U>(_ transform: (Element) -> U?) -> [U] {
        var result = [U]()
        
        for t in self {
            if let u = transform(t) {
                result.append(u)
            }
        }
        return result
    }
    
    func limit(_ exclusiveUpperBound: Int) -> [Element] {
        return self.count < exclusiveUpperBound ? self : Array(self[0..<exclusiveUpperBound])
    }
    
    /**
        Takes an equality comparer and returns a new array containing all the distinct elements.
    */
    func distinct(_ comparer: (Element, Element) -> Bool) -> [Element] {
        var result = [Element]()
        for t in self {
            // if there are no elements in the result set equal to this element, add it
            if !result.any({ comparer($0, t) }) {
                result.append(t)
            }
        }
        return result
    }
    
    func all(_ predicate: (Element) -> Bool) -> Bool {
        for t in self {
            if !predicate(t) {
                return false
            }
        }
        return true
    }
    
    /**
        Maps a function using the corresponding elements of two arrays.
    */
    func mapPairs<U>(_ otherArray: [Element], transform: (Element, Element) -> U) -> [U] {
        var result = [U]()
        let size = self.count < otherArray.count ? self.count : otherArray.count
        for i in 0 ..< size {
            result.append(transform(self[i], otherArray[i]))
        }
        return result
    }
    
    /// Returns an array of function applications to all pairs of elements.
    /// The size of the resulting array is 1 less than the size of the input array.
    func mapAdjacentElements<U>(_ transform: (Element, Element) -> U) -> [U] {
        var result = [U]()
        for i in 0..<(self.count - 1) {
            result.append(transform(self[i], self[i + 1]))
        }
        return result
    }
    
    func tryGet(_ index: Int) -> Element? {
        return self.count > index ? self[index] : nil
    }
    
    func toDictionary<Key, Value>(_ transform: (Element) -> (Key, Value)) -> [Key : Value] {
        var result = [Key : Value]()
        for t in self {
            let (k,v) = transform(t)
            result[k] = v
        }
        return result
    }
}

extension Dictionary {
    func map<Key2,Value2>(_ transform: (Key, Value) -> (Key2, Value2)) -> [Key2 : Value2] {
        var resultDictionary = [Key2 : Value2]()
        for (key, value) in self {
            let resultPair = transform(key, value)
            resultDictionary[resultPair.0] = resultPair.1
        }
        return resultDictionary
    }
    
    func mapUnwrap<Key2, Value2>(_ transform: (Key, Value) -> (key: Key2, value: Value2)?) -> [Key2 : Value2] {
        var resultDictionary = [Key2 : Value2]()
        for (key, value) in self {
            if let resultPair = transform(key, value) {
                resultDictionary[resultPair.key] = resultPair.value
            }
        }
        return resultDictionary
    }
    
    func tryGet(_ key: Key?) -> Value? {
        return key == nil ? nil : self[key!]
    }
}
