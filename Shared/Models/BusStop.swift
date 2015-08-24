//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

struct BusStop : Equatable {
    let id: Int
    let name: String
    let location: CLLocation
    let routeNames: [String]
    
    private init(id: Int, name: String, location: CLLocation, routeNames: [String]) {
        self.id = id
        self.name = name
        self.location = location
        self.routeNames = routeNames
    }
    
    static func fromDictionary(dictionary: [String : AnyObject]) -> BusStop? {
        guard let id = dictionary["ID"] as? Int,
            let name = dictionary["Name"] as? String,
            let lat = dictionary["Lat"] as? Double,
            let long = dictionary["Long"] as? Double,
            let routeNames = dictionary["RouteNames"] as? [String] else {
                return nil
        }
        return BusStop(id: id, name: name,
            location: CLLocation(latitude: lat, longitude: long),
            routeNames: routeNames)
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.id == rhs.id
}