//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

func toBusStop(data: [String : AnyObject]) -> BusStop? {
    let id = data["ID"] as? Int
    if id == nil { return nil }
    
    let name = data["Name"] as? String
    if name == nil { return nil }
    
    let road = data["Road"] as? String
    if road == nil { return nil }
    
    let lat = data["Lat"] as? Double
    if lat == nil { return nil }
    
    let long = data["Long"] as? Double
    if long == nil { return nil }
    
    return BusStop(id: id!, name: name!, road: road!,
        location: CLLocation(latitude: lat!, longitude: long!))
}

class BusStop : Equatable {
    let id: Int
    let name: String
    let road: String
    let location: CLLocation
    var distanceFromUser: CLLocationDistance?
    var isNearestStop = false
    
    private init(id: Int, name: String, road: String, location: CLLocation) {
        self.id = id
        self.name = name
        self.road = road
        self.location = location
    }
    
    var friendlyDistance: String {
        get {
            if self.distanceFromUser != nil {
                let metersToMiles = 0.000621371
                let distanceInMiles = String(format: "%1.1f", self.distanceFromUser! * metersToMiles)
                return distanceInMiles + " miles"
            }
            return ""
        }
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.id == rhs.id
}