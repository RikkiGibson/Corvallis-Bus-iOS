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
                    //.distinct(==)
                    .sorted() { $0.arrivalTime.compare($1.arrivalTime) == NSComparisonResult.OrderedAscending }
                return (intKey, busArrivals)
            }
        }
        return nil
    }
}

// two bus arrivals for the same route within one minute
// of each other are considered redundant-- the API is buggy
func == (lhs: BusArrival, rhs: BusArrival) -> Bool {
    return lhs.route == rhs.route && lhs.arrivalTime.timeIntervalSinceDate(rhs.arrivalTime) < 60
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
    
    private let formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    var friendlyEta: String {
        get {
            let etaInSeconds = self.arrivalTime.timeIntervalSinceNow
            switch etaInSeconds {
            case 0...60: return "less than 1 minute"
            case 60...1800: // 1 minute - 30 minutes from now
                let minutesDescription = String(format: "%0.0f", etaInSeconds / 60)

                // the format string is rounding to the nearest integer, so < 90 rounds to 1
                return minutesDescription + (etaInSeconds < 90 ? " minute" : " minutes")
            default: // just show the arrival time
                return self.formatter.stringFromDate(self.arrivalTime)
            }
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

func friendlyMapArrivals(arrivals: [BusArrival]) -> String {
    if arrivals.count >= 2 {
        return arrivals[0].friendlyEta + ", " + arrivals[1].friendlyEta
    }
    return arrivals.count > 0 ? arrivals[0].friendlyEta : "No arrivals!"
}

let arrivalsSummary: [BusArrival] -> String = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .NoStyle
    formatter.timeStyle = .ShortStyle
    
    return { arrivals in
        if arrivals.count <= 2 {
            return ""
        }
        let secondToLastTime = arrivals[arrivals.count - 2].arrivalTime
        let lastTime = arrivals[arrivals.count - 1].arrivalTime
        
        let difference = lastTime.timeIntervalSinceDate(secondToLastTime)
        
        switch difference {
        case 1700.0...1900.0: return "Every 30 minutes until \(formatter.stringFromDate(lastTime))"
        case 3500.0...3700.0: return "Hourly until \(formatter.stringFromDate(lastTime))"
        default:
            return ""
        }
    }
}()