//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

class BusStop : Equatable {
    let id = 0
    let name = ""
    let road = ""
    let location = CLLocation()
    var distanceFromUser: CLLocationDistance?
    
    
    init?(data: [String: AnyObject]) {
        var id = data["ID"] as? Int
        if id == nil { return nil }
        self.id = id!
        
        var name = data["Name"] as? String
        if name == nil { return nil }
        self.name = name!
        
        var road = data["Road"] as? String
        if road == nil { return nil }
        self.road = road!
        
        var lat = data["Lat"] as? Double
        if lat == nil { return nil }
        
        var long = data["Long"] as? Double
        if long == nil { return nil }
        
        self.location = CLLocation(latitude: lat!, longitude: long!)
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