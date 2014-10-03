//
//  LookupList.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

struct LookupLists {
    private static let rootUrl = "http://www.corvallis-bus.appspot.com"
    /**
        Gets the static list of bus stops.
        If the list has not yet been obtained, executes an optional callback.
    */
    private static var _stops: [BusStop]?
    static func stops(callback: () -> Void = { () in }) -> [BusStop]? {
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
                callback()
            }).resume()
        }
        
        return _stops;
    }
    
    /**
        Gets the static list of routes.
        If the list has not yet been obtained, executes an optional callback.
    */
    private static var _routes: [BusRoute]?
    static func routes(callback: () -> Void = { () in }) -> [BusRoute]? {
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
                    callback()
            }).resume()
        }
        
        return _routes;
    }
    
    /**
        Gets the list of arrivals for the provided stop IDs.
        When more than 10 stops are provided, a data task for each 10 stops is spawned off and the results are aggregated before the caller's callback is executed.
    */
    static func arrivals(stops: [Int], callback: () -> Void) -> [(id: Int, arrivals:[BusArrival])]? {
        var joinedStops = stops.reduce("") { $0.description + ", " + $1.description }
        var url = NSURL(string: "\(rootUrl)/arrivals?stops=\(joinedStops)")
        
        var result: [(id: Int, arrivals:[BusArrival])]?
        
        var session = NSURLSession.sharedSession();
        session.dataTaskWithURL(url, completionHandler: {
                data, response, error -> Void in
            if (error != nil) {
                println(error.description)
            }
            
            var jsonError: NSError?
            var arrivalJson = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as NSArray as [[String : AnyObject]]
            
            if (jsonError != nil) {
                println(jsonError!.description)
            }
            
            callback()
        })
        
        return result;
    }
}