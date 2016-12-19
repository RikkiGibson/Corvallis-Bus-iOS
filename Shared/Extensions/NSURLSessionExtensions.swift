//
//  NSURLSessionExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/21/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension URLSession {
    func downloadData(_ url: URL) -> Promise<Data, BusError> {
        let sanitizeAPI = { (data: Data?, response: URLResponse?, error: NSError?) -> Failable<Data, BusError> in
            if let error = error {
                return .error(BusError.fromNSError(error))
            } else {
                return .success(data!)
            }
        }
        
        return Promise { (completionHandler: @escaping (Failable<Data, BusError>) -> Void) in
            self.dataTask(with: url, completionHandler: {
                let failable = sanitizeAPI($0, $1, $2 as NSError?)
                completionHandler(failable)
            }).resume()
        }
    }
}
