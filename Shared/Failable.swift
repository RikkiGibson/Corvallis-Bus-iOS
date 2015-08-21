//
//  Failable.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 4/20/15.
//  Copyright (c) 2015 Rikki Gibson. All rights reserved.
//

import Foundation

enum Failable<T> {
    case Success(T)
    case Error(NSError)
    
    func map<U>(transform: T -> Failable<U>) -> Failable<U> {
        switch self {
        case Success(let value):
            return transform(value)
        case Error(let error):
            return .Error(error)
        }
    }
    
    func map<U>(transform: T -> U) -> Failable<U> {
        switch self {
        case Success(let value):
            return .Success(transform(value))
        case Error(let error):
            return .Error(error)
        }
    }
    
    /// Converts the Failable<T> to an Optional<T> such that Success(T) converts to Some(T)
    /// and Error converts to None.
    func toOptional() -> T? {
        switch self {
        case .Success(let value):
            return value
        default:
            return nil
        }
    }
    
    /// Converts the Failable<T> to an Optional<T> such that Error(NSError) converts to Some(NSError)
    /// and Error converts to None.
    func toError() -> NSError? {
        switch self {
        case .Error(let error):
            return error
        default:
            return nil
        }
    }
}