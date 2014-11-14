//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

func toBusRoute(data: [String: AnyObject]) -> BusRoute? {
    
    let name = data["Name"] as? String
    if name == nil { return nil }
    
    let additionalName = data["AdditionalName"] as? String
    if additionalName == nil { return nil }
    
    let description = data["Description"] as? String
    if description == nil { return nil }
    
    let path = data["Path"] as? [[String: AnyObject]]
    
    let polyline = MKPolyline(GMEncodedString: data["Polyline"] as? String)
    if polyline == nil { return nil }
    
    return BusRoute(name: name!, additionalName: additionalName!,
        routeDescription: description!, polyline: polyline!, path: path)
}

class BusRoute {
    let name: String
    let additionalName: String
    let routeDescription: String
    let polyline: MKPolyline
    private var _path: [[String: AnyObject]]?
    lazy var path: [BusStop] = {
        if self._path != nil {
            var result = self._path!.mapUnwrap() { toBusStop($0) }
            self._path = nil // causes deallocation
            return result
        }
        return [BusStop]()
    }()
    
    private init(name: String, additionalName: String, routeDescription: String,
        polyline: MKPolyline, path: [[String: AnyObject]]?) {
            self.name = name
            self.additionalName = additionalName
            self.routeDescription = routeDescription
            self.polyline = polyline
            self._path = path
    }
}