//
//  NSURLSessionExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/21/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSURLSession {
    func downloadData(url: NSURL) -> Promise<NSData> {
        let sanitizeAPI = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Failable<NSData> in
            if let error = error {
                return .Error(error)
            } else {
                return .Success(data!)
            }
        }
        
        return Promise { (completionHandler: Failable<NSData> -> Void) in
            self.dataTaskWithURL(url, completionHandler: {
                let failable = sanitizeAPI($0, $1, $2)
                completionHandler(failable)
            }).resume()
        }
    }
}