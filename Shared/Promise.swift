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

enum PromiseState<T, E: Error> {
    case created
    case started
    case finished(Failable<T, E>)
}

class Promise<T, E: Error> {
    typealias CompletionHandler = (Failable<T, E>) -> Void
    typealias AsyncOperation = (@escaping CompletionHandler) -> Void
    
    let operation: AsyncOperation
    
    private(set) var state = PromiseState<T, E>.created
    private var completionHandlers: [CompletionHandler] = []
    
    init(operation: @escaping AsyncOperation) {
        self.operation = operation
    }
    
    init(result: T) {
        self.operation = { completionHandler in
            completionHandler(.success(result))
        }
    }
    
    func start(_ handler: @escaping CompletionHandler) {
        switch state {
        case .created:
            completionHandlers.append(handler)
            start()
        case .started:
            completionHandlers.append(handler)
        case .finished(let result):
            handler(result)
        }
    }
    
    private func start() {
        self.state = .started
        self.operation { result in
            self.state = .finished(result)
            for handler in self.completionHandlers {
                handler(result)
            }
        }
    }
    
    /// Prevents the promise from calling completion handlers previously provided to it.
    func cancel() {
        completionHandlers = []
    }
    
    func startOnMainThread(_ completion: @escaping CompletionHandler) {
        self.start{ result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func map<U>(_ transform: @escaping (T) -> U) -> Promise<U, E> {
        return Promise<U, E>(operation: { (completionHandler: @escaping Promise<U, E>.CompletionHandler) in
            self.start { failable in
                let foo = failable.map(transform)
                completionHandler(foo)
            }
        })
    }
    
    func map<U>(_ transform: @escaping (T) -> Promise<U, E>) -> Promise<U, E> {
        return Promise<U, E> { (completionHandler: @escaping Promise<U, E>.CompletionHandler) in
            self.start { failable in
                switch failable {
                case .success(let t):
                    transform(t).start(completionHandler)
                case .error(let error):
                    completionHandler(.error(error))
                }
            }
        }
    }
    
    func map<U>(_ transform: @escaping (Failable<T, E>) -> Promise<U, E>) -> Promise<U, E> {
        return Promise<U, E> { (completionHandler: @escaping Promise<U, E>.CompletionHandler) in
            self.start { failable in transform(failable).start(completionHandler) }
        }
    }
    
    func map<U>(_ transform: @escaping (T) -> Failable<U, E>) -> Promise<U, E> {
        return Promise<U, E> { (completionHandler: @escaping Promise<U, E>.CompletionHandler) in
            self.start { failable in completionHandler(failable.map(transform)) }
        }
    }
}
