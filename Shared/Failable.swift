//
//  Failable.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 4/20/15.
//  Copyright (c) 2015 Rikki Gibson. All rights reserved.
//

import Foundation

enum BusError : Error {
    case message(String)
    case nonNotify
    
    func getMessage() -> String? {
        switch self {
        case .message(let message):
            return message
        default:
            return nil
        }
    }
    
    /// Produces a BusError from an NSError.
    /// Determines whether to show the error based on the code
    /// and whether there's a user-friendly message to show.
    static func fromNSError(_ error: NSError) -> BusError {
        if let message = error.userInfo[NSLocalizedDescriptionKey] as? String,
            URLError.Code.init(rawValue: error.code) != URLError.timedOut
        {
            return .message(message)
        } else {
            return .nonNotify
        }
    }
}

/// Represents an asynchronously obtained resource that is reloaded over time.
enum Resource<T, E: Error> {
    case loading
    case success(T)
    case error(E)
    
    static func fromFailable(_ failable: Failable<T, E>) -> Resource<T, E> {
        switch failable {
        case Failable.success(let value):
            return .success(value)
        case Failable.error(let err):
            return .error(err)
        }
    }
}

func ??<T, E: Error>(resource: Resource<T, E>, replacementValue: T) -> T {
    if case .success(let value) = resource {
        return value
    } else {
        return replacementValue
    }
}

enum Failable<T, E: Error> {
    case success(T)
    case error(E)
    
    func map<U>(_ transform: (T) -> Failable<U, E>) -> Failable<U, E> {
        switch self {
        case .success(let value):
            return transform(value)
        case .error(let error):
            return .error(error)
        }
    }
    
    func map<U>(_ transform: (T) -> U) -> Failable<U, E> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .error(let error):
            return .error(error)
        }
    }
    
    func unwrap() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .error(let error):
            throw error
        }
    }
    
    /// Converts the Failable<T> to an Optional<T> such that Success(T) converts to Some(T)
    /// and Error converts to None.
    func toOptional() -> T? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }
    
    /// Converts the Failable<T> to an Optional<T> such that Error(NSError) converts to Some(NSError)
    /// and Error converts to None.
    func toError() -> E? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}

func ??<T, E: Error>(failable: Failable<T, E>, replacementValue: T) -> T {
    if case .success(let value) = failable {
        return value
    } else {
        return replacementValue
    }
}

extension Optional {
    func toFailable() -> Failable<Wrapped, BusError> {
        if let value = self {
            return .success(value)
        } else {
            return .error(.nonNotify)
        }
    }
}
