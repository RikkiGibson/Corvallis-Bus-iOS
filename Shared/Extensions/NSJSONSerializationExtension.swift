//
//  NSJSONSerializationExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSJSONSerialization {
    private static func parseJSON<T>(data: NSData) -> Failable<T, BusError> {
        if let json = try? JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)),
            let typedJSON = json as? T {
            return Failable<T, BusError>.Success(typedJSON)
        } else {
            return .Error(.NonNotify)
        }
    }
    
    static func parseJSONArray(data: NSData) -> Failable<[[String : AnyObject]], BusError> {
        return parseJSON(data)
    }
    
    static func parseJSONObject(data: NSData) -> Failable<[String : AnyObject], BusError> {
        return parseJSON(data)
    }
}
