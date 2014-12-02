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
    
    // Use all the routes where the route's path contains this stop
    return BusStop(id: id!, name: name!, road: road!,
        location: CLLocation(latitude: lat!, longitude: long!), routes: routes)
}

class BusStop : Equatable {
    let id: Int
    let name: String
    let road: String
    let location: CLLocation
    
    private var _routes: () -> [BusRoute]
    lazy var routes: [BusRoute] = {
        if self._routes != nil {
            let applicableRoutes = self._routes().filter() { $0.path.any() { $0 == self.id } }
            return applicableRoutes
        }
        return [BusRoute]()
    }()
    var distanceFromUser: CLLocationDistance?
    var isNearestStop = false
    
    private init(id: Int, name: String, road: String, location: CLLocation, routes: () -> [BusRoute]) {
        self.id = id
        self.name = name
        self.road = road
        self.location = location
        self._routes = routes
    }
    
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
                    secondArrival!.arrivalTime) == NSComparisonResult.OrderedAscending
            }
        }
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