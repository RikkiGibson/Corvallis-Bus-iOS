//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

typealias StopArrival = (id: Int, arrivals: [BusArrival])

private func toStopArrival(key: String, value: [String: AnyObject]) -> StopArrival? {
    var arrivals: [BusArrival]?
    arrivals <<<<* (value as AnyObject)
    
    var intKey = key.toInt()
    
    if intKey != nil && arrivals != nil {
        return (id: intKey!, arrivals: arrivals!)
    }
    return nil
}

func toStopArrivals(data: [String : AnyObject]) -> [StopArrival] {
    var result = [StopArrival]()
    // keys are stop IDs
    // values are a list of bus arrivals
    // good luck.
    
    for (key, value) in data {
        var arrival = toStopArrival(key, value as [String : AnyObject])
        if arrival != nil {
            result.append(arrival!)
        }
    }
    return result
}

class BusArrival : Deserializable {
    var expected: NSDate?
    var route: String?
    var scheduled: NSDate?
    
    required init(data: [String : AnyObject]) {
        self.expected <<< data["Expected"]
        self.route <<< data["Route"]
        self.scheduled <<< data["Scheduled"]
    }
}