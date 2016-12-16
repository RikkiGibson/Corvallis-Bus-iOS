//
//  Failable.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 4/20/15.
//  Copyright (c) 2015 Rikki Gibson. All rights reserved.
//

import Foundation

enum BusError : ErrorType {
    case Message(String)
    case NonNotify
    
    func getMessage() -> String? {
        switch self {
        case .Message(let message):
            return message
        default:
            return nil
        }
    }
    
    /// Produces a BusError from an NSError.
    /// Determines whether to show the error based on the code
    /// and whether there's a user-friendly message to show.
    static func fromNSError(error: NSError) -> BusError {
        if let message = error.userInfo[NSLocalizedDescriptionKey] as? String
        where NSURLError(rawValue: error.code) != NSURLError.TimedOut {
            return .Message(message)
        } else {
            return .NonNotify
        }
    }
}

/// Represents an asynchronously obtained resource that is reloaded over time.
enum Resource<T, E: ErrorType> {
    case Loading
    case Success(T)
    case Error(E)
    
    func fromFailable(failable: Failable<T, E>) -> Resource<T, E> {
        switch failable {
        case Failable.Success(let value):
            return .Success(value)
        case Failable.Error(let err):
            return .Error(err)
        }
    }
}

func ??<T, E: ErrorType>(resource: Resource<T, E>, replacementValue: T) -> T {
    if case .Success(let value) = resource {
        return value
    } else {
        return replacementValue
    }
}

enum Failable<T, E: ErrorType> {
    case Success(T)
    case Error(E)
    
    func map<U>(transform: T -> Failable<U, E>) -> Failable<U, E> {
        switch self {
        case Success(let value):
            return transform(value)
        case Error(let error):
            return .Error(error)
        }
    }
    
    func map<U>(transform: T -> U) -> Failable<U, E> {
        switch self {
        case Success(let value):
            return .Success(transform(value))
        case Error(let error):
            return .Error(error)
        }
    }
    
    func unwrap() throws -> T {
        switch self {
        case Success(let value):
            return value
        case Error(let error):
            throw error
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
    func toError() -> E? {
        switch self {
        case .Error(let error):
            return error
        default:
            return nil
        }
    }
}

func ??<T, E: ErrorType>(failable: Failable<T, E>, replacementValue: T) -> T {
    if case .Success(let value) = failable {
        return value
    } else {
        return replacementValue
    }
}

extension Optional {
    func toFailable() -> Failable<Wrapped, BusError> {
        if let value = self {
            return .Success(value)
        } else {
            return .Error(.NonNotify)
        }
    }
}
