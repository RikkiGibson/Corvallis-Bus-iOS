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
    var ID: Int?
    var Name: String?
    var Road: String?
    var Bearing: Double?
    var AdherancePoint: Bool?
    var Location: CLLocation?
    var distanceFromUser: CLLocationDistance?

    // Required because of reasons
    init() { }
    
    init(data: [String: AnyObject]) {
        var cursor: AnyObject?
        cursor = data["ID"]
        self.ID = cursor as? Int
        
        cursor = data["Name"]
        self.Name = cursor as? String
        
        cursor = data["Road"]
        self.Road = cursor as? String
        
        cursor = data["Bearing"]
        self.Bearing = cursor as? Double
        
        cursor = data["AdherancePoint"]
        self.AdherancePoint = cursor as? Bool
        
        cursor = data["Lat"]
        var lat = cursor as? Double
        
        cursor = data["Long"]
        var long = cursor as? Double
        
        if lat != nil && long != nil {
            self.Location = CLLocation(latitude: lat!, longitude: long!)
        }
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.ID == rhs.ID
}