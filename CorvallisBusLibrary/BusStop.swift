//
//  BusStop.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

func toBusStop(data: [String : AnyObject], withRoutes routes: () -> [BusRoute]) -> BusStop? {
    if let id = data["ID"] as? Int,
        let name = data["Name"] as? String,
        let lat = data["Lat"] as? Double,
        let long = data["Long"] as? Double {
        return BusStop(id: id, name: name, location: CLLocation(latitude: lat, longitude: long),
            routes: routes)
    }
    return nil
}

final class BusStop : Equatable {
    let id: Int
    let name: String
    let location: CLLocation
    
    private var _routes: () -> [BusRoute]
    
    /// Returns the routes applicable to this stop. Computed on demand.
    lazy var routes: [BusRoute] = self._routes().filter() { $0.path.any() { $0 == self.id } }
    
    var distanceFromUser: CLLocationDistance?
    var isNearestStop = false
    
    private init(id: Int, name: String, location: CLLocation, routes: () -> [BusRoute]) {
        self.id = id
        self.name = name
        self.location = location
        self._routes = routes
    }
    
    /// Returns the routes applicable to this stop, sorted with the routes arriving soonest at the top.
    func routesSortedByArrivals(arrivals: [BusArrival]) -> [BusRoute] {
        return self.routes.sorted() { firstRoute, secondRoute in
            let firstArrival = arrivals.first() { $0.route == firstRoute.name }
            let secondArrival = arrivals.first() { $0.route == secondRoute.name }
            if firstArrival == nil {
                return false
            } else if secondArrival == nil {
                return true
            } else {
                return firstArrival!.arrivalTime.compare(
                    secondArrival!.arrivalTime) == .OrderedAscending
            }
        }
    }
    
    let MILES_PER_METER = 0.000621371
    var friendlyDistance: String {
        get {
            if let distanceInMeters = self.distanceFromUser {
                let distanceInMiles = distanceInMeters * MILES_PER_METER
                return String(format: "%1.1f miles", distanceInMiles)
            } else {
                return ""
            }
        }
    }
}
    
func == (lhs: BusStop, rhs: BusStop) -> Bool {
    return lhs.id == rhs.id
}