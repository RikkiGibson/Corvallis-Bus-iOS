//
//  NSJSONSerializationExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    private static func parseJSON<T>(data: NSData) -> Failable<T> {
        do {
            if let json = try JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? T {
                return .Success(json)
            } else {
                return .Error(NSError(domain: "CorvallisBus", code: 0, userInfo: nil))
            }
        } catch let error as NSError {
            return .Error(error)
        } catch {
            return .Error(NSError(domain: "CorvallisBus", code: 0, userInfo: nil))
        }
    }
    
    static func parseJSONArray(data: NSData) -> Failable<[[String : AnyObject]]> {
        return parseJSON(data)
    }
    
    static func parseJSONObject(data: NSData) -> Failable<[String : AnyObject]> {
        return parseJSON(data)
    }
}