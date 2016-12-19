//
//  NSJSONSerializationExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension JSONSerialization {
    private static func parseJSON<T>(_ data: Data) -> Failable<T, BusError> {
        if let json = try? jsonObject(with: data, options: []),
            let typedJSON = json as? T {
            return Failable<T, BusError>.success(typedJSON)
        } else {
            return .error(.nonNotify)
        }
    }
    
    static func parseJSONArray(_ data: Data) -> Failable<[[String : AnyObject]], BusError> {
        return parseJSON(data)
    }
    
    static func parseJSONObject(_ data: Data) -> Failable<[String : AnyObject], BusError> {
        return parseJSON(data)
    }
}
