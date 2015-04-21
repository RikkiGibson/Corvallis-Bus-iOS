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

final class CorvallisBusService {
    private static let rootUrl = "http://www.corvallis-bus.appspot.com"
    private static let locationManagerDelegate = CorvallisBusLocationManagerDelegate()
    
    private static var _callqueue = Array<Failable<[BusStop]> -> Void>()
    private static var _stops: [BusStop]?
    
    /// Calls all the callbacks in the queue with the given error and empties the queue.
    private static func _failWithError(error: NSError) {
        let error = Failable<[BusStop]>.Error(error)
        for callback in _callqueue {
            callback(error)
        }
        _callqueue.removeAll()
    }
    
    /// Executes a callback using the list of stops from the Corvallis Bus server.
    /// Since stops need to have route info baked in, requests for stops and routes are sent in parallel.
    /// Thus, when this function calls back, it can be assumed that both stops and routes are cached.
    static func stops(callback: Failable<[BusStop]> -> Void) -> Void {
        // If data is in the cache, call back immediately.
        if _stops != nil {
            callback(.Success(Box(self._stops!)))
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
                        callback(.Success(Box(self._stops!)))
                    }
                }
            }
            
            let stopsURL = NSURL(string: "\(rootUrl)/stops")!
            let stopsRequest = NSURLRequest(URL: stopsURL, cachePolicy: .ReloadIgnoringLocalCacheData,
                timeoutInterval: 10.0)
            
            session.dataTaskWithRequest(stopsRequest) {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        self._failWithError(error)
                        return
                    }
                    
                    var jsonError: NSError?
                    stopsJson = (NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("stops") as! [[String : AnyObject]])
                    
                    if (jsonError != nil) {
                        self._failWithError(jsonError!)
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
                    self._failWithError(error)
                    return
                }
                
                var jsonError: NSError?
                routesJson = (NSJSONSerialization.JSONObjectWithData(data,
                    options: .AllowFragments,
                    error: &jsonError)?.objectForKey("routes") as! [[String : AnyObject]])
                
                if (jsonError != nil) {
                    self._failWithError(jsonError!)
                    return
                }
                finally()
            }.resume()
        }
    }
    
    private static var _routes: (() -> [BusRoute])?
    
    /// Executes a callback using the list of routes from the Corvallis Bus server.
    /// The first time this is called, the route data is deserialized.
    static func routes(callback: (Failable<[BusRoute]>) -> Void) -> Void {
        if self._routes != nil {
            callback(.Success(Box(self._routes!())))
        } else {
            // Stops have route information baked in. Therefore a callback by stops() guarantees that
            // either route data is in the cache or an error occurred.
            CorvallisBusService.stops() { stops in
                switch stops {
                case .Success(let value):
                    callback(.Success(Box(self._routes!())))
                case .Error(let error):
                    callback(.Error(error))
                }
            }
        }
    }
    
    /// Executes a callback using the arrival information for the provided list of stop IDs.
    static func arrivals(stops: [Int], callback: Failable<[Int : [BusArrival]]> -> Void) -> Void {
        // no point in getting arrival times for 0 bus stops
        // especially when doing so crashes the app
        if !stops.any() {
            callback(.Success(Box([Int : [BusArrival]]())))
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
                callback(.Error(error))
                return
            }
            
            var jsonError: NSError?
            let arrivalJson = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as! [String: AnyObject]
            
            if (jsonError != nil) {
                callback(.Error(jsonError!))
                return
            }
            callback(.Success(Box(toStopArrivals(arrivalJson))))
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
    
    /**
        Executes a callback using a list of the user's favorite stops.
        Asynchronously obtains the user's location and the user's list of favorite stops.
        Invokes a private function that only executes the user's callback once both operations have completed.
    */
    static func favorites(callback: Failable<[BusStop]> -> Void) -> Void {
        self.locationManagerDelegate.userLocation() { maybeLocation in
            self.stops() { maybeStops in
                switch maybeStops {
                case .Error(let error):
                    // no stops is a showstopper heh!
                    callback(maybeStops)
                    break
                case .Success(let box):
                    let stops = box.value
                    switch maybeLocation {
                    case .Error:
                        // have stops, but no location
                        let favorites = self._filterDownToFavorites(stops)
                        self._resetStopDistances(favorites, location: nil)
                        callback(.Success(Box(favorites)))
                        return
                    case .Success(let locationBox):
                        // both location and stops
                        let sortedFavorites = self._sortFavorites(stops, location: locationBox.value)
                        callback(.Success(Box(sortedFavorites)))
                        break
                    }
                    break
                }
            }
        }
    }
    
    private static func _filterDownToFavorites(allStops: [BusStop]) -> [BusStop] {
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
        let favoriteIds = defaults.objectForKey("Favorites") as? NSArray ?? NSArray()
        return allStops.filter({ favoriteIds.containsObject($0.id) })
    }
    
    private static func _resetStopDistances(stops: [BusStop], location: CLLocation?) -> [BusStop] {
        for stop in stops {
            stop.distanceFromUser = location?.distanceFromLocation(stop.location)
            stop.isNearestStop = false
        }
        return stops
    }
    
    private static func _sortFavorites(stops: [BusStop], location: CLLocation) -> [BusStop] {
        // Sorting an empty list is easy
        if !stops.any() {
            return stops
        }
        
        var favorites = _filterDownToFavorites(stops)
        if self.shouldShowNearestStop {
            // Finding the nearest stop requires calculating distance from all stops
            self._resetStopDistances(stops, location: location)
            let nearestStop = stops.reduce(stops.first!) {
                $0.distanceFromUser < $1.distanceFromUser ? $0 : $1
            }
            // Mark as nearest stop only if it's not already a favorite stop
            if !favorites.any(predicate: { $0.id == nearestStop.id }) {
                nearestStop.isNearestStop = true
                favorites.append(nearestStop)
            }
        } else {
            // If nearest stop is undesired, only favorite stops need to have their location calculated
            self._resetStopDistances(favorites, location: location)
        }
        
        favorites.sort() { $0.distanceFromUser < $1.distanceFromUser }
        return favorites
    }
    
    static func setFavorites(favorites: [BusStop]) -> Void {
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
        let favoriteIds = NSArray(array: favorites.map() { $0.id })
        defaults.setObject(favoriteIds, forKey: "Favorites")
        defaults.synchronize()
    }
    
}