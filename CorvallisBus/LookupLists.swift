//
//  LookupList.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

struct LookupLists {
    private static var _stops: [BusStop]?
    static func stops(callback: () -> Void = { () in }) -> [BusStop]? {
        if _stops == nil {
            var session = NSURLSession.sharedSession()
            session.dataTaskWithURL(NSURL(string: "http://www.corvallis-bus.appspot.com/stops"),
            completionHandler: {
                (data, response, error) -> Void in
                if (error != nil) {
                    println(error.description)
                }
                
                var jsonError: NSError?
                var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                    options: NSJSONReadingOptions.AllowFragments,
                    error: &jsonError)?.objectForKey("stops") as NSArray as [[String : AnyObject]]
                
                if (jsonError != nil) {
                    println(jsonError?.description)
                }
                
                self._stops = stopJson.map() { dict -> BusStop in BusStop(data: dict) }
                callback()
            }).resume()
        }
        
        return _stops;
    }
    
    private static var _routes: [BusRoute]?
    static func routes(callback: () -> Void = { () in }) -> [BusRoute]? {
        if _routes == nil {
            var session = NSURLSession.sharedSession()
            session.dataTaskWithURL(NSURL(string: "http://www.corvallis-bus.appspot.com/routes"),
                completionHandler: {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        println(error.description)
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions.AllowFragments,
                        error: &jsonError)?.objectForKey("routes") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError?.description)
                    }
                    
                    self._routes = stopJson.map() { dict -> BusRoute in BusRoute(data: dict) }
                    callback()
            }).resume()
        }
        
        return _routes;
    }
}