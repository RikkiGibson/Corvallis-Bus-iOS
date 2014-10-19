//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

class BusStop : Deserializable, Equatable {
    var ID: Int?
    var Name: String?
    var Road: String?
    var Bearing: Double?
    var AdherancePoint: Bool?
    var Location: CLLocation?

    // Required because of reasons
    init() { }
    
    required init(data: [String: AnyObject]) {
        self.ID <<< data["ID"]
        self.Name <<< data["Name"]
        self.Road <<< data["Road"]
        self.Bearing <<< data["Bearing"]
        self.AdherancePoint <<< data["AdherancePoint"]
        
        var lat: Double?; lat <<< data["Lat"]
        var long: Double?; long <<< data["Long"]
        if lat != nil && long != nil {
            self.Location = CLLocation(latitude: lat!, longitude: long!)
        }
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.ID == rhs.ID &&
        lhs.Name == rhs.Name &&
        lhs.Road == rhs.Road &&
        lhs.Bearing == rhs.Bearing &&
        lhs.AdherancePoint == rhs.AdherancePoint &&
        lhs.Location!.distanceFromLocation(rhs.Location).isZero
}