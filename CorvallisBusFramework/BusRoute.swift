//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusRoute {
    let name: String
    let additionalName: String
    let routeDescription: String
    private var _path: [[String: AnyObject]]?
    lazy var path: [BusStop]? = {
        if self._path != nil {
            var result = self._path!.mapUnwrap() { BusStop(data: $0) }
            self._path = nil // causes deallocation
            return result
        }
        return nil
    }()
    
    init?(data: [String : AnyObject]) {
        self.name = ""
        self.additionalName = ""
        self.routeDescription = ""
        
        var name = data["Name"] as? String
        if name == nil { return nil }
        self.name = name!
        
        var additionalName = data["AdditionalName"] as? String
        if additionalName == nil { return nil }
        self.additionalName = additionalName!
        
        var description = data["Description"] as? String
        if description == nil { return nil }
        self.routeDescription = description!
        
        self._path = data["Path"] as? [[String: AnyObject]]
    }
}