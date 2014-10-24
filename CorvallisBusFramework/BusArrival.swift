//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

private func toStopArrival(key: String, value: AnyObject) -> (id: Int, arrivals: [BusArrival])? {
    var busArrivals: [BusArrival]?
    
    var busArrivalJson = value as? [[String : AnyObject]]
    if busArrivalJson != nil {
        busArrivals = busArrivalJson!.mapUnwrap() { BusArrival(data: $0) }
    }
    
    var intKey = key.toInt()
    if intKey != nil && busArrivals != nil {
        return (id: intKey!, arrivals: busArrivals!)
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
        var arrival = toStopArrival(key, value)
        if arrival != nil {
            result[arrival!.id] = arrival!.arrivals
        }
    }
    return result
}

let toNSDate = { () -> (AnyObject? -> NSDate?) in
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "dd MMM yy HH:mm ZZZ"
    
    return {
        if ($0 != nil && $0 is String) {
            return dateFormatter.dateFromString($0 as String)
        }
        return nil
    }
}()

class BusArrival {
    let route: String
    let arrivalTime: NSDate
    
    init?(data: [String : AnyObject]) {
        self.route = ""
        self.arrivalTime = NSDate()
        
        var route = data["Route"] as? String
        if route == nil { return nil }
        self.route = route!
        
        let expected = toNSDate(data["Expected"])
        let scheduled = toNSDate(data["Scheduled"])
        
        if expected == nil && scheduled == nil { return nil }
        self.arrivalTime = (expected ?? scheduled)!
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