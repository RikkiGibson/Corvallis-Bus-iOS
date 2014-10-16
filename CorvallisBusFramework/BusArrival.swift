//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

typealias StopArrival = (id: Int, arrivals: [BusArrival])

private func toStopArrival(key: String, value: AnyObject) -> StopArrival? {
    var arrivals: [BusArrival]?
    arrivals <<<<* value
    
    var intKey = key.toInt()
    
    if intKey != nil && arrivals != nil {
        return (id: intKey!, arrivals: arrivals!)
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

// what is this, javascript?
let toNSDate = { () -> (AnyObject? -> NSDate?) in
    let dateFormatter = NSDateFormatter()
    
    return { obj in
        if (obj != nil && obj is String) {
            return dateFormatter.dateFromString(obj as String)
        }
        return nil
    }
}()

class BusArrival : Deserializable {
    var expected: NSDate?
    var route: String?
    var scheduled: NSDate?
    
    required init(data: [String : AnyObject]) {
        self.expected <<< (value: data["Expected"], format: "dd MMM yy HH:mm ZZZ")
        self.route <<< data["Route"]
        self.scheduled <<< (value: data["Scheduled"], format: "dd MMM yy HH:mm ZZZ")
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