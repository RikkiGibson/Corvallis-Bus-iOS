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
        if let intKey = key.toInt(), let busArrivalsJson = value as? [[String : AnyObject]] {
            let sortedArrivals = busArrivalsJson.mapUnwrap(toBusArrival)
                .distinct(==)
                .sorted({ $0.arrivalTime.compare($1.arrivalTime) == .OrderedAscending })
            return (intKey, sortedArrivals)
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
    let dateParser = NSDateFormatter()
    dateParser.dateFormat = "dd MMM yy HH:mm ZZZ"
    
    return { obj in
        if let string = obj as? String {
            return dateParser.dateFromString(string)
        } else {
            return nil
        }
    }
}()

func toBusArrival(data: [String : AnyObject]) -> BusArrival? {
    if let route = data["Route"] as? String,
        let arrivalTime = toNSDate(data["Expected"]) ?? toNSDate(data["Scheduled"]) {
        return BusArrival(route: route, arrivalTime: arrivalTime)
    } else {
        return nil
    }
}

let arrivalFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .NoStyle
    formatter.timeStyle = .ShortStyle
    return formatter
}()

struct BusArrival {
    let route: String
    let arrivalTime: NSDate
    
    private init(route: String, arrivalTime: NSDate) {
        self.route = route
        self.arrivalTime = arrivalTime
    }
    
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
                return arrivalFormatter.stringFromDate(self.arrivalTime)
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
    switch arrivals.count {
    case 0: return "No arrivals!"
    case 1: return arrivals[0].friendlyEta
    default: return arrivals[0].friendlyEta + ", " + arrivals[1].friendlyEta
    }
}

func arrivalsSummary(arrivals: [BusArrival]) -> String {
    switch arrivals.count {
    case 0...2:
        return ""
    case 3:
        let lastTime = arrivals[2].arrivalTime
        return "Last arrival at \(arrivalFormatter.stringFromDate(lastTime))"
    default:
        let differences = mapAdjacentElements(arrivals[1..<arrivals.count]) { firstArrival, secondArrival in
            secondArrival.arrivalTime.timeIntervalSinceDate(firstArrival.arrivalTime)
        }
        let lastTime = arrivalFormatter.stringFromDate(arrivals.last!.arrivalTime)
        if differences.all({ $0 >= 1200 && $0 <= 2400 }) {
            return "Every 30 minutes until \(lastTime)"
        } else if differences.all({ $0 >= 3000 && $0 <= 4200}) {
            return "Hourly until \(lastTime)"
        } else {
            return "Last arrival at \(lastTime)"
        }
    }
}