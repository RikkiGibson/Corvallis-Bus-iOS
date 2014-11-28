//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

/**
    A stop arrival is a key-value pair in a dictionary where a stop ID can be provided
    to receive a list of bus arrival times for that stop.
*/
func toStopArrivals(data: [String : AnyObject]) -> [Int : [BusArrival]] {
    return data.mapUnwrap() { (key, value) in
        if let busArrivalJson = value as? [[String : AnyObject]] {
            if let intKey = key.toInt() {
                let busArrivals = busArrivalJson.mapUnwrap() { toBusArrival($0) }
                    .sorted() { $0.arrivalTime.compare($1.arrivalTime) == NSComparisonResult.OrderedAscending }
                return (intKey, busArrivals)
            }
        }
        return nil
    }
}

private let toNSDate = { () -> (AnyObject? -> NSDate?) in
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "dd MMM yy HH:mm ZZZ"
    
    return { obj in
        if let string = obj as? String {
            return dateFormatter.dateFromString(string)
        }
        return nil
    }
}()

func toBusArrival(data: [String : AnyObject]) -> BusArrival? {
    let route = data["Route"] as? String
    if route == nil { return nil }
    
    if let expected = toNSDate(data["Expected"]) {
        return BusArrival(route: route!, arrivalTime: expected)
    } else if let scheduled = toNSDate(data["Expected"]) {
        return BusArrival(route: route!, arrivalTime: scheduled)
    }
    return nil
}

class BusArrival {
    let route: String
    let arrivalTime: NSDate
    
    private init(route: String, arrivalTime: NSDate) {
        self.route = route
        self.arrivalTime = arrivalTime
    }
    
    var friendlyEta: String {
        get {
            let etaInMinutes = self.arrivalTime.timeIntervalSinceDate(NSDate()) / 60
            return etaInMinutes < 1 ? "less than 1 minute" :
                String(format: "%0.0f", etaInMinutes) + " minutes"
        }
    }
    
    var description: String {
        get {
            return "Route \(self.route): \(self.friendlyEta)"
        }
    }
}

/**
    Converts an array of bus arrivals to a friendly informational string.
*/
func friendlyArrivals(arrivals: [BusArrival]) -> String {
    if arrivals.count >= 2 {
        return arrivals[0].description + "\n" + arrivals[1].description
    }
    return arrivals.count > 0 ? arrivals[0].description : "No arrivals!"
}