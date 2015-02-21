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
                    .distinct(==)
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
    return lhs.route == rhs.route && abs(lhs.arrivalTime.timeIntervalSinceDate(rhs.arrivalTime)) < 60
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
        if arrivals.count == 3 {
            let lastTime = arrivals[2].arrivalTime
            return "Last arrival at \(formatter.stringFromDate(lastTime))"
        }
        
        let latterArrivals = Array(arrivals[2..<arrivals.count])
        let formerArrivals = Array(arrivals[1..<arrivals.count-1])
        
        let differences = latterArrivals.mapPairs(formerArrivals) { firstArrival, secondArrival in
            firstArrival.arrivalTime.timeIntervalSinceDate(secondArrival.arrivalTime)
        }
        
        let lastTime = formatter.stringFromDate(arrivals.last!.arrivalTime)
        if differences.all({ $0 >= 1200 && $0 <= 2400 }) {
            return "Every 30 minutes until \(lastTime)"
        } else if differences.all({ $0 >= 3000 && $0 <= 4200}) {
            return "Hourly until \(lastTime)"
        } else {
            return "Last arrival at \(lastTime)"
        }
    }
}()