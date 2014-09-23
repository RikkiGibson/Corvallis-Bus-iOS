//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusStop {
    let ID: Int
//    let Name: String
//    let Road: String
//    let Bearing: Double
//    let AdherancePoint: Bool
//    let Lat: Double
//    let Long: Double
//    let Distance: Double
    
    init(json: Dictionary<String, AnyObject>) {
        if let id: String = json["ID"]?.value {
            self.ID = id.toInt()!
        }
//        self.Name = json["Name"]
//        self.Road = json["Road"]
//        self.Bearing = json["Bearing"]
//        self.AdherancePoint = json["AdherancePoint"]
//        self.Lat = json["Lat"]
//        self.Long = json["Long"]
//        self.Distance = json["Distance"]
    }
}