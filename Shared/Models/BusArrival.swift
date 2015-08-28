//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

typealias RouteSchedules = [String : [Int]]
typealias StopSchedules = [Int : RouteSchedules]

func parseRouteSchedule(json: [String : AnyObject]) -> RouteSchedules {
    return json.mapUnwrap{ (key: String, value: AnyObject) -> (String, [Int])? in
        if let value = value as? [Int] {
            return (key, value)
        } else {
            return nil
        }
    }
}

func parseSchedule(json: [String : AnyObject]) -> StopSchedules {
    guard let json = json as? [String : [String : AnyObject]] else {
        return StopSchedules()
    }
    return json.mapUnwrap{ (key: String, value: [String : AnyObject]) -> (Int, RouteSchedules)? in
        if let key = Int(key) {
            return (key, parseRouteSchedule(value))
        } else {
            return nil
        }
    }
}

func arrivalTimeDescription(minutes: Int) -> String {
    switch minutes {
    case 1:
        return "1 minute"
    case 2...30:
        return "\(minutes) minutes"
    default:
        let date = NSDate(timeIntervalSinceNow: NSTimeInterval(minutes * 60))
        return arrivalFormatter.stringFromDate(date)
    }
}

let arrivalFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .NoStyle
    formatter.timeStyle = .ShortStyle
    return formatter
}()

func friendlyMapArrivals(arrivals: [Int]) -> String {
    switch arrivals.count {
    case 0: return "No arrivals!"
    case 1:
        let date = NSDate(timeIntervalSinceNow: NSTimeInterval(arrivals[0] * 60))
        return arrivalFormatter.stringFromDate(date)
    default:
        let firstDate = NSDate(timeIntervalSinceNow: NSTimeInterval(arrivals[0] * 60))
        let secondDate = NSDate(timeIntervalSinceNow: NSTimeInterval(arrivals[1] * 60))
        return arrivalFormatter.stringFromDate(firstDate) + ", " +
            arrivalFormatter.stringFromDate(secondDate)
    }
}

func toArrivalsSummary(arrivalTimes: [Int]) -> String {
    switch arrivalTimes.count {
    case 0...2:
        return ""
    case 3:
        let lastTime = NSDate(timeIntervalSinceNow: NSTimeInterval(arrivalTimes[2] * 60))
        return "Last arrival at \(arrivalFormatter.stringFromDate(lastTime))"
    default:
        let differences = mapAdjacentElements(arrivalTimes[1..<arrivalTimes.count]) { $0 - $1 }
        let lastDate = NSDate(timeIntervalSinceNow: NSTimeInterval(arrivalTimes.last! * 60))
        let lastDateString = arrivalFormatter.stringFromDate(lastDate)
        if differences.all({ $0 >= 1200 && $0 <= 2400 }) {
            return "Every 30 minutes until \(lastDateString)"
        } else if differences.all({ $0 >= 3000 && $0 <= 4200}) {
            return "Hourly until \(lastDateString)"
        } else {
            return "Last arrival at \(lastDateString)"
        }
    }
}