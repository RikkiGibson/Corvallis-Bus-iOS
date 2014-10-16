//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusStop : Deserializable, Equatable {
    var ID: Int?
    var Name: String?
    var Road: String?
    var Bearing: Double?
    var AdherancePoint: Bool?
    var Lat: Double?
    var Long: Double?

    // Required because of reasons
    init() { }
    
    required init(data: [String: AnyObject]) {
        self.ID <<< data["ID"]
        self.Name <<< data["Name"]
        self.Road <<< data["Road"]
        self.Bearing <<< data["Bearing"]
        self.AdherancePoint <<< data["AdherancePoint"]
        self.Lat <<< data["Lat"]
        self.Long <<< data["Long"]
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.ID == rhs.ID &&
        lhs.Name == rhs.Name &&
        lhs.Road == rhs.Road &&
        lhs.Bearing == rhs.Bearing &&
        lhs.AdherancePoint == rhs.AdherancePoint &&
        lhs.Lat == rhs.Lat &&
        lhs.Long == rhs.Long
}