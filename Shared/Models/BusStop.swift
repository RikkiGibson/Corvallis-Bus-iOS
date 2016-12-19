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
    let bearing: Double
    let location: CLLocation
    let routeNames: [String]
    
    static func fromDictionary(_ dictionary: [String : AnyObject]) -> BusStop? {
        guard let id = dictionary["id"] as? Int,
            let name = dictionary["name"] as? String,
            let bearing = dictionary["bearing"] as? Double,
            let lat = dictionary["lat"] as? Double,
            let long = dictionary["lng"] as? Double,
            let routeNames = dictionary["routeNames"] as? [String] else {
                return nil
        }
        return BusStop(id: id, name: name, bearing: toCGFriendlyAngle(bearing),
            location: CLLocation(latitude: lat, longitude: long),
            routeNames: routeNames)
    }
    
    static func toCGFriendlyAngle(_ bearingDegrees: Double) -> Double {
        return (bearingDegrees / 180.0 * M_PI + M_PI / 2.0).truncatingRemainder(dividingBy: (M_PI * 2.0));
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.id == rhs.id
}
