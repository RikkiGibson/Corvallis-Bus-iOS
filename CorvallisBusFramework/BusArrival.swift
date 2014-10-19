//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

// A StopArrival contains the stop ID and a list of times
// that a particular route will arrive at that stop.
typealias StopArrival = (id: Int, arrivals: [BusArrival])

private func toStopArrival(key: String, value: AnyObject) -> StopArrival? {
    var busArrivals: [BusArrival]?
    
    var busArrivalJson = value as? [[String : AnyObject]]
    if busArrivalJson != nil {
        busArrivals = busArrivalJson!.map() { BusArrival(data: $0) }
    }
    
    var intKey = key.toInt()
    if intKey != nil && busArrivals != nil {
        return (id: intKey!, arrivals: busArrivals!)
    }
    return nil
}

func toStopArrivals(data: [String : AnyObject]) -> [StopArrival] {
    var result = [StopArrival]()
    
    for (key, value) in data {
        var arrival = toStopArrival(key, value)
        if arrival != nil {
            result.append(arrival!)
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
    var expected: NSDate?
    var route: String?
    var scheduled: NSDate?
    
    init(data: [String : AnyObject]) {
        var cursor: AnyObject?
        cursor = data["Expected"]
        self.expected = toNSDate(cursor)
        
        cursor = data["Route"]
        self.route = cursor as? String
        
        cursor = data["Scheduled"]
        self.scheduled = toNSDate(cursor)
    }
    
    
    var description: String {
        get {
            let date = expected ?? scheduled
            if date != nil && self.route != nil {
                let etaInMinutes = String(format: "%0.0f", date!.timeIntervalSinceDate(NSDate.date()) / 60)
                return "Route \(self.route!): \(etaInMinutes) minutes"
            }
            return ""
        }
    }
}