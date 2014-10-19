//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusRoute {
    var name: String?
    var additionalName: String?
    var routeDescription: String?
    var url: String?
    private var _path: [[String: AnyObject]]?
    lazy var path: [BusStop]? = {
        if self._path != nil {
            return self._path!.map() { BusStop(data: $0) }
        }
        return nil
    }()
    
    // Required because of reasons
    init() { }
    
    init(data: [String : AnyObject]) {
        var cursor: AnyObject?
        
        cursor = data["Name"]
        self.name = cursor as? String
        
        cursor = data["AdditionalName"]
        self.additionalName = cursor as? String
        
        cursor = data["Description"]
        self.routeDescription = cursor as? String
        
        cursor = data["URL"]
        self.url = cursor as? String
        
        cursor = data["Path"]
        self._path = cursor as? [[String: AnyObject]]
    }
    
    var description: String {
        get {
            if self.name != nil && self.additionalName != nil {
                return String(format:"%@: %@", self.name!, self.additionalName!)
            }
            return ""
        }
    }
}