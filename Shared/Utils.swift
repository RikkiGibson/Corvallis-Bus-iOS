//
//  Utils.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/18/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

func memoize<T, Key : Hashable, Value>(f: T -> Value, getHash: T -> Key) -> (T -> Value) {
    var memo = [Key : Value]()
    return {
        if memo[getHash($0)] == nil {
            memo[getHash($0)] = f($0)
        }
        return memo[getHash($0)]!
    }
}

/// Maps a function using the corresponding elements of two sequences.
func mapPairs<S: SequenceType, T: SequenceType, U>(seq1: S, seq2: T,
    transform: (S.Generator.Element, T.Generator.Element) -> U) -> [U] {
        var result = [U]()
        var generator1 = seq1.generate()
        var generator2 = seq2.generate()
        while let element1 = generator1.next() {
            if let element2 = generator2.next() {
                result.append(transform(element1, element2))
            } else {
                break
            }
        }
        return result
}

func mapAdjacentElements<S: SequenceType, U>(seq: S,
    transform: (S.Generator.Element, S.Generator.Element) -> U) -> [U] {
        var result = [U]()
        var generator = seq.generate()
        var prev = generator.next()
        while let current = generator.next() where prev != nil {
            result.append(transform(prev!, current))
            prev = current
        }
        return result
}

extension Set {
    func mapUnwrap<U>(transform: Element -> U?) -> Set<U> {
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
    func any(predicate: Element -> Bool = { t in true }) -> Bool {
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
    func first(predicate: Element -> Bool = { t in true }) -> Element? {
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
    func mapUnwrap<U>(transform: Element -> U?) -> [U] {
        var result = [U]()
        
        for t in self {
            if let u = transform(t) {
                result.append(u)
            }
        }
        return result
    }
    
    func limit(exclusiveUpperBound: Int) -> [Element] {
        return self.count < exclusiveUpperBound ? self : Array(self[0..<exclusiveUpperBound])
    }
    
    /**
        Takes an equality comparer and returns a new array containing all the distinct elements.
    */
    func distinct(comparer: (Element, Element) -> Bool) -> [Element] {
        var result = [Element]()
        for t in self {
            // if there are no elements in the result set equal to this element, add it
            if !result.any({ comparer($0, t) }) {
                result.append(t)
            }
        }
        return result
    }
    
    func all(predicate: Element -> Bool) -> Bool {
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
    func mapPairs<U>(otherArray: [Element], transform: (Element, Element) -> U) -> [U] {
        var result = [U]()
        let size = self.count < otherArray.count ? self.count : otherArray.count
        for var i = 0; i < size; i++ {
            result.append(transform(self[i], otherArray[i]))
        }
        return result
    }
    
    /// Returns an array of function applications to all pairs of elements.
    /// The size of the resulting array is 1 less than the size of the input array.
    func mapAdjacentElements<U>(transform: (Element, Element) -> U) -> [U] {
        var result = [U]()
        for i in 0..<(self.count - 1) {
            result.append(transform(self[i], self[i + 1]))
        }
        return result
    }
    
    func tryGet(index: Int) -> Element? {
        return self.count > index ? self[index] : nil
    }
    
    func toDictionary<Key, Value>(transform: Element -> (Key, Value)) -> [Key : Value] {
        var result = [Key : Value]()
        for t in self {
            let tuple = transform(t)
            result[tuple.0] = tuple.1
        }
        return result
    }
}

extension Dictionary {
    func map<Key2,Value2>(transform: (Key, Value) -> (Key2, Value2)) -> [Key2 : Value2] {
        var resultDictionary = [Key2 : Value2]()
        for (key, value) in self {
            let resultPair = transform(key, value)
            resultDictionary[resultPair.0] = resultPair.1
        }
        return resultDictionary
    }
    
    func mapUnwrap<Key2, Value2>(transform: (Key, Value) -> (key: Key2, value: Value2)?) -> [Key2 : Value2] {
        var resultDictionary = [Key2 : Value2]()
        for (key, value) in self {
            if let resultPair = transform(key, value) {
                resultDictionary[resultPair.key] = resultPair.value
            }
        }
        return resultDictionary
    }
    
    func tryGet(key: Key?) -> Value? {
        return key == nil ? nil : self[key!]
    }
}