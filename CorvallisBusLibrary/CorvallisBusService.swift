//
//  LookupList.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

struct CorvallisBusService {
    private static let rootUrl = "http://www.corvallis-bus.appspot.com"
    private static let locationManagerDelegate = CorvallisBusLocationManagerDelegate()
    
    private static var _callqueue = Array<[BusStop] -> Void>()
    private static var _stops: [BusStop]?
    
    /// Executes a callback using the list of stops from the Corvallis Bus server.
    /// Since stops need to have route info baked in, requests for stops and routes are sent in parallel.
    /// Thus, when this function calls back, it can be assumed that both stops and routes are cached.
    static func stops(callback: [BusStop] -> Void) -> Void {
        // If data is in the cache, call back immediately.
        if _stops != nil {
            callback(self._stops!)
            // Calls being in the queue already implies the task has started already.
        } else if _callqueue.any() {
            _callqueue.append(callback)
        } else {
            _callqueue.append(callback)
            
            let session = NSURLSession.sharedSession()
            
            var stopsJson: [[String : AnyObject]]?
            var routesJson: [[String : AnyObject]]?
            
            let finally = { () -> Void in
                if stopsJson != nil && routesJson != nil {
                    // The work to create the route objects is deferred
                    // by wrapping it in a closure.
                    var routesCache: [BusRoute]?
                    self._routes = {
                        if routesCache == nil {
                            routesCache = routesJson!.mapUnwrap() { toBusRoute($0) }
                        }
                        return routesCache!
                    }
                    
                    self._stops = stopsJson!.mapUnwrap() { toBusStop($0, withRoutes: self._routes!) }
                    for callback in self._callqueue {
                        callback(self._stops!)
                    }
                }
            }
            
            let stopsURL = NSURL(string: "\(rootUrl)/stops")!
            let stopsRequest = NSURLRequest(URL: stopsURL, cachePolicy: .ReloadIgnoringLocalCacheData,
                timeoutInterval: 10.0)
            
            session.dataTaskWithRequest(stopsRequest) {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        let empty = [BusStop]()
                        for callback in self._callqueue {
                            callback(empty)
                        }
                        self._callqueue = Array<[BusStop] -> Void>()
                        return
                    }
                    
                    var jsonError: NSError?
                    stopsJson = (NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("stops") as! [[String : AnyObject]])
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                        return
                    }
                    finally()
            }.resume()
            
            let routesURL = NSURL(string: "\(rootUrl)/routes?stops=true")!
            let routesRequest = NSURLRequest(URL: routesURL, cachePolicy: .ReloadIgnoringLocalCacheData,
                timeoutInterval: 10.0)
            
            session.dataTaskWithRequest(routesRequest) {
                (data, response, error) -> Void in
                if (error != nil) {
                    let empty = [BusStop]()
                    for callback in self._callqueue {
                        callback(empty)
                    }
                    self._callqueue = Array<[BusStop] -> Void>()
                    return
                }
                
                var jsonError: NSError?
                routesJson = (NSJSONSerialization.JSONObjectWithData(data,
                    options: .AllowFragments,
                    error: &jsonError)?.objectForKey("routes") as! [[String : AnyObject]])
                
                if (jsonError != nil) {
                    println(jsonError!.description)
                    return
                }
                finally()
            }.resume()
            
            
        }
    }
    
    private static var _routes: (() -> [BusRoute])?
    
    /// Executes a callback using the list of routes from the Corvallis Bus server.
    /// The first time this is called, the route data is deserialized.
    static func routes(callback: ([BusRoute]) -> Void) -> Void {
        if self._routes != nil {
            callback(self._routes!())
        } else {
            // Stops have route information baked in. Therefore a callback by stops() guarantees that
            // either route data is in the cache or an error occurred.
            CorvallisBusService.stops() { stops in
                callback(self._routes?() ?? [BusRoute]())
            }
        }
    }
    
    /// Executes a callback using the arrival information for the provided list of stop IDs.
    static func arrivals(stops: [Int], callback: [Int : [BusArrival]] -> Void) -> Void {
        // no point in getting arrival times for 0 bus stops
        // especially when doing so crashes the app
        if !stops.any() {
            callback([Int : [BusArrival]]())
            return
        }
        
        var joinedStops = ",".join(stops.map() { String($0) })
        
        let session = NSURLSession.sharedSession()
        
        let url = NSURL(string: "\(rootUrl)/arrivals?stops=\(joinedStops)")!
        let request = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData,
            timeoutInterval: 10.0)
        
        session.dataTaskWithRequest(request, completionHandler: {
            data, response, error in
            if (error != nil) {
                callback([Int : [BusArrival]]())
                return
            }
            
            var jsonError: NSError?
            let arrivalJson = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as! [String: AnyObject]
            
            if (jsonError != nil) {
                println(jsonError!.description)
                return
            }
            callback(toStopArrivals(arrivalJson))
        }).resume()
    }
    
    private static let nearestStopKey = "shouldShowNearestStop"
    static var shouldShowNearestStop: Bool {
        get {
            let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
            return defaults.objectForKey(nearestStopKey) as? Bool ?? true // default
        }
        set {
            let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
            defaults.setObject(newValue, forKey: nearestStopKey)
            defaults.synchronize()
        }
    }
    
    private static let todayViewItemCountKey = "todayViewItemCount"
    static var todayViewItemCount: Int {
        get {
            let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
            return defaults.objectForKey(todayViewItemCountKey) as? Int ?? 7 // default
        }
        set(value) {
            let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
            defaults.setObject(value, forKey: todayViewItemCountKey)
            defaults.synchronize()
        }
    }
    
    /// This ensures that a new location is obtained before sorting and calling back with favorite stops.
    private static var _updatedLocation: Bool = false
    private static var _userLocation: CLLocation?
    
    /**
        Executes a callback using a list of the user's favorite stops.
        Asynchronously obtains the user's location and the user's list of favorite stops.
        Invokes a private function that only executes the user's callback once both operations have completed.
    */
    static func favorites(callback: [BusStop] -> Void) -> Void {
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
        let favoriteIds = defaults.objectForKey("Favorites") as? NSArray ?? NSArray()
        
        locationManagerDelegate.userLocation() {
            self._updatedLocation = true
            self._userLocation = $0
            self._getSortedFavorites(favoriteIds, callback: callback)
        }
        
        self.stops() { stops in
            if !stops.any() {
                callback(stops)
            }
            self._getSortedFavorites(favoriteIds, callback: callback)
        }
    }
    
    /**
        Finally executes the client's callback with the favorites list.
        If location is enabled, favorites are sorted by proximity.
        If location and show nearest stop is enabled, includes the nearest stop
        marked with isNearestStop = true, if the nearest stop is not already in favorites.
    */
    private static func _getSortedFavorites(favoriteIds: NSArray, callback: [BusStop] -> Void) -> Void {
        if self._stops == nil || self._stops!.count < 1 || !self._updatedLocation {
            return
        }
        // location disabled: return just the filtered list of favorites, with no location in
        // location enabled: return the filtered list of favorites, plus potentially the nearest stop
        var favorites = self._stops!.filter() { favoriteIds.containsObject($0.id) }
        if self._userLocation != nil {
            if self.shouldShowNearestStop {
                for stop in self._stops! {
                    stop.distanceFromUser = stop.location.distanceFromLocation(self._userLocation!)
                    stop.isNearestStop = false
                }
                let nearestStop = self._stops!.reduce(self._stops!.first!) {
                    $0.distanceFromUser < $1.distanceFromUser ? $0 : $1
                }
                // Mark as nearest stop only if it's not already a favorite stop
                if !favorites.any(predicate: { $0.id == nearestStop.id }) {
                    nearestStop.isNearestStop = true
                    favorites.append(nearestStop)
                }
            } else {
                for stop in favorites {
                    stop.distanceFromUser = stop.location.distanceFromLocation(self._userLocation!)
                    stop.isNearestStop = false
                }
            }
            favorites.sort() { $0.distanceFromUser < $1.distanceFromUser }
            self._userLocation = nil
        } else {
            // location is not available
            for stop in favorites {
                stop.distanceFromUser = nil
                stop.isNearestStop = false
            }
        }
        
        self._updatedLocation = false
        callback(favorites)
    }
    
    static func setFavorites(favorites: [BusStop]) -> Void {
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
        let favoriteIds = NSArray(array: favorites.map() { $0.id })
        defaults.setObject(favoriteIds, forKey: "Favorites")
        defaults.synchronize()
    }
    
}