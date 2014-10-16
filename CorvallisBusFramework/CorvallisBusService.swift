//
//  LookupList.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

struct CorvallisBusService {
    private static let rootUrl = "http://www.corvallis-bus.appspot.com"
    /**
    Gets the cached list of bus stops. Executes a callback to allow assignment to a
    variable in the calling scope or to act upon the result set.
    */
    private static var _stops: [BusStop]?
    static func stops(callback: ([BusStop]) -> Void) -> Void {
        if _stops == nil {
            var session = NSURLSession.sharedSession()
            session.dataTaskWithURL(NSURL(string: "\(rootUrl)/stops"),
                completionHandler: {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        println(error.description)
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("stops") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                    }
                    
                    self._stops = stopJson.map() { BusStop(data: $0) }
                    callback(self._stops!)
            }).resume()
        }
        else {
            callback(self._stops!)
        }
    }
    
    /**
    Gets the cached list of routes.
    If the list has not yet been obtained, executes an optional callback.
    */
    private static var _routes: [BusRoute]?
    static func routes(callback: ([BusRoute]) -> Void) -> Void {
        if _routes == nil {
            var session = NSURLSession.sharedSession()
            session.dataTaskWithURL(NSURL(string: "\(rootUrl)/routes"),
                completionHandler: {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        println(error.description)
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("routes") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                    }
                    
                    self._routes = stopJson.map() { BusRoute(data: $0) }
                    callback(self._routes!)
            }).resume()
        }
        else {
            callback(self._routes!)
        }
    }
    
    /**
    Gets the list of arrivals for the provided stop IDs.
    */
    static func arrivals(stops: [Int], callback: ([StopArrival]) -> Void) -> Void {
        var joinedStops = ",".join(stops.map() { String($0) })
        var urlString = "\(rootUrl)/arrivals?stops=\(joinedStops)"
        var url = NSURL(string: "\(rootUrl)/arrivals?stops=\(joinedStops)")
        
        var session = NSURLSession.sharedSession();
        session.dataTaskWithURL(url, completionHandler: {
            data, response, error -> Void in
            if (error != nil) {
                println(error.description)
            }
            
            var jsonError: NSError?
            var arrivalJson = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as NSDictionary as [String: AnyObject]
            
            if (jsonError != nil) {
                println(jsonError!.description)
            }
            
            callback(toStopArrivals(arrivalJson))
        }).resume()
    }
}