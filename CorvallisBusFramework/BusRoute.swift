//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusRoute : Deserializable {
    var name: String?
    var additionalName: String?
    var description: String?
    var url: String?
    var path: [BusStop]?
    
    // Required because of reasons
    init() { }
    
    required init(data: [String : AnyObject]) {
        self.name <<< data["Name"]
        self.additionalName <<< data["AdditionalName"]
        self.description <<< data["Description"]
        self.url <<< data["URL"]
        var path: AnyObject? = data["Path"]
        if let value: AnyObject = path {
            if value is [AnyObject] {
                self.path <<<<* value
            }
        }
    }
}