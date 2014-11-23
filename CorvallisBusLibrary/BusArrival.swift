//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

private func toStopArrival(key: String, value: AnyObject) -> (id: Int, arrivals: [BusArrival])? {
    if let busArrivalJson = value as? [[String : AnyObject]] {
        if let intKey = key.toInt() {
            let busArrivals = busArrivalJson.mapUnwrap() { toBusArrival($0) }
            return (id: intKey, arrivals: busArrivals)
        }
    }
    return nil
}

/**
    A stop arrival is a key-value pair in a dictionary where a stop ID can be provided
    to receive a list of bus arrival times for that stop.
*/
func toStopArrivals(data: [String : AnyObject]) -> [Int : [BusArrival]] {
    var result = [Int : [BusArrival]]()
    
    for (key, value) in data {
        if let arrival = toStopArrival(key, value) {
            result[arrival.id] = arrival.arrivals
        }
    }
    return result
}

private let toNSDate = { () -> (AnyObject? -> NSDate?) in
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "dd MMM yy HH:mm ZZZ"
    
    return {
        if ($0 != nil && $0 is String) {
            return dateFormatter.dateFromString($0 as String)
        }
        return nil
    }
}()

func toBusArrival(data: [String : AnyObject]) -> BusArrival? {
    let route = data["Route"] as? String
    if route == nil { return nil }
    
    let expected = toNSDate(data["Expected"])
    let scheduled = toNSDate(data["Scheduled"])
    
    if expected == nil && scheduled == nil { return nil }
    
    return BusArrival(route: route!, arrivalTime: (expected ?? scheduled)!)
}

class BusArrival {
    let route: String
    let arrivalTime: NSDate
    
    private init(route: String, arrivalTime: NSDate) {
        self.route = route
        self.arrivalTime = arrivalTime
    }
    
    var description: String {
        get {
            let etaInMinutes = self.arrivalTime.timeIntervalSinceDate(NSDate()) / 60
            let friendlyEta = etaInMinutes < 1 ? "less than 1 minute" :
                String(format: "%0.0f", etaInMinutes) + " minutes"
            return "Route \(self.route): \(friendlyEta)"
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