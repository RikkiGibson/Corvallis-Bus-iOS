//
//  NSURLSessionExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/21/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSURLSession {
    func downloadJSON<T>(url: NSURL, callback: Failable<T> -> Void) {
        dataTaskWithURL(url) {
            data, response, error in
            guard error == nil else {
                callback(.Error(error!))
                return
            }
            do {
                if let data = data,
                   let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? T {
                    callback(.Success(json))
                    return
                } else {
                    // JSON wasn't of the right type
                }
            } catch let error as NSError {
                callback(.Error(error))
                return
            } catch {
                // can this ever happen?
            }
        }.resume()
    }
    
    func downloadJSONArray(url: NSURL, callback: Failable<[[String : AnyObject]]> -> Void) {
        downloadJSON(url, callback: callback)
    }
    
    func downloadJSONDictionary(url: NSURL, callback: Failable<[String : AnyObject]> -> Void) {
        downloadJSON(url, callback: callback)
    }
}