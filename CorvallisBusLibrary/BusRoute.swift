//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

class BusRoute {
    let name = ""
    let additionalName = ""
    let routeDescription = ""
    let polyline = MKPolyline()
    private var _path: [[String: AnyObject]]?
    lazy var path: [BusStop] = {
        if self._path != nil {
            var result = self._path!.mapUnwrap() { BusStop(data: $0) }
            self._path = nil // causes deallocation
            return result
        }
        return [BusStop]()
    }()
    
    init?(data: [String : AnyObject]) {
        
        let name = data["Name"] as? String
        if name == nil { return nil }
        self.name = name!
        
        let additionalName = data["AdditionalName"] as? String
        if additionalName == nil { return nil }
        self.additionalName = additionalName!
        
        let description = data["Description"] as? String
        if description == nil { return nil }
        self.routeDescription = description!
        
        self._path = data["Path"] as? [[String: AnyObject]]
        
        let polylineString = data["Polyline"] as? String
        if polylineString == nil { return nil }
        self.polyline = MKPolyline(GMEncodedString: polylineString)
    }
}