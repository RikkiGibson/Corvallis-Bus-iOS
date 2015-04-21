//
//  Failable.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 4/20/15.
//  Copyright (c) 2015 Rikki Gibson. All rights reserved.
//

import Foundation

final class Box<T> {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

enum Failable<T> {
    case Success(Box<T>)
    case Error(NSError)
    
    func MakeSuccess(value: T) -> Failable<T> {
        return .Success(Box(value))
    }
    
    func map<U>(transform: T -> Failable<U>) -> Failable<U> {
        switch self {
        case Success(let value):
            return transform(value.value)
        case Error(let error):
            return .Error(error)
        }
    }
    
    func map<U>(transform: T -> U) -> Failable<U> {
        switch self {
        case Success(let box):
            return .Success(Box(transform(box.value)))
        case Error(let error):
            return .Error(error)
        }
    }
}