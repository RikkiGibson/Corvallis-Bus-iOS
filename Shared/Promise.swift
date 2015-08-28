//
//  Promise.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//  Based heavily on the "Back to the Futures" talk by Javier Soto.
//  https://realm.io/news/swift-summit-javier-soto-futures/
//

import Foundation

class Promise<T, E: ErrorType> {
    typealias CompletionHandler = Failable<T, E> -> Void
    typealias AsyncOperation = (CompletionHandler) -> Void
    
    let operation: AsyncOperation
    
    init(_ operation: AsyncOperation) {
        self.operation = operation
    }
    
    func start(completion: CompletionHandler) {
        self.operation(completion)
    }
    
    func startOnMainThread(completion: CompletionHandler) {
        self.start{ result in
            dispatch_async(dispatch_get_main_queue()) {
                completion(result)
            }
        }
    }
    
    func map<U>(transform: T -> U) -> Promise<U, E> {
        return Promise<U, E> { completionHandler in
            self.start { failable in
                completionHandler(failable.map(transform))
            }
        }
    }
    
    func map<U>(transform: T -> Promise<U, E>) -> Promise<U, E> {
        return Promise<U, E> { completionHandler in
            self.start { failable in
                switch failable {
                case .Success(let t):
                    transform(t).start(completionHandler)
                case .Error(let error):
                    completionHandler(.Error(error))
                }
            }
        }
    }
    
    func map<U>(transform: Failable<T, E> -> Promise<U, E>) -> Promise<U, E> {
        return Promise<U, E> { completionHandler in
            self.start { failable in transform(failable).start(completionHandler) }
        }
    }
    
    func map<U>(transform: T -> Failable<U, E>) -> Promise<U, E> {
        return Promise<U, E> { completionHandler in
            self.start { failable in completionHandler(failable.map(transform)) }
        }
    }
}
