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
    
    private static var _stops: [BusStop]?
    /**
        Executes a callback using the list of stops from the Corvallis Bus server.
    */
    static func stops(callback: [BusStop] -> Void) -> Void {
        if _stops == nil {
            var session = NSURLSession.sharedSession()
            var url = NSURL(string: "\(rootUrl)/stops")
            
            if url == nil {
                println("NSURL did not instantiate properly")
                return
            }
            
            session.dataTaskWithURL(url!,
                completionHandler: {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        println(error.description)
                        return
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("stops") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                        return
                    }
                    
                    self._stops = stopJson.mapUnwrap() { toBusStop($0) }
                    callback(self._stops!)
            }).resume()
        }
        else {
            callback(self._stops!)
        }
    }
    
    /**
        Executes a callback using the list of routes from the Corvallis Bus server.
    */
    private static var _routes: [BusRoute]?
    static func routes(callback: ([BusRoute]) -> Void) -> Void {
        if _routes == nil {
            var session = NSURLSession.sharedSession()
            var url = NSURL(string: "\(rootUrl)/routes?stops=true")
            
            if url == nil {
                println("NSURL did not instantiate properly")
                return
            }
            
            session.dataTaskWithURL(url!,
                completionHandler: {
                    (data, response, error) -> Void in
                    if (error != nil) {
                        println(error.description)
                        return
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("routes") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                        return
                    }
                    
                    self._routes = stopJson.mapUnwrap() { toBusRoute($0) }
                    callback(self._routes!)
            }).resume()
        }
        else {
            callback(self._routes!)
        }
    }
    
    /**
        Executes a callback using the arrival information for the provided list of stop IDs.
    */
    static func arrivals(stops: [Int], callback: [Int : String] -> Void) -> Void {
        // no point in getting arrival times for 0 bus stops
        // especially when doing so crashes the app
        if !stops.any() {
            callback([Int : String]())
            return
        }
        
        var joinedStops = ",".join(stops.map() { String($0) })
        var url = NSURL(string: "\(rootUrl)/arrivals?stops=\(joinedStops)")
        if url == nil {
            println("NSURL did not instantiate properly")
            return
        }
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(url!, completionHandler: {
            data, response, error in
            if (error != nil) {
                println(error.description)
                return
            }
            
            var jsonError: NSError?
            let arrivalJson = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &jsonError) as NSDictionary as [String: AnyObject]
            
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
            if let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus") {
                if let preference = defaults.objectForKey(nearestStopKey) as? Bool {
                    return preference
                }
            }
            return true // default
        }
        set {
            if let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus") {
                defaults.setObject(newValue, forKey: nearestStopKey)
                defaults.synchronize()
            }
        }
    }
    
    private static let todayViewItemCountKey = "todayViewItemCount"
    static var todayViewItemCount: Int {
        get {
            if let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus") {
                if let preference = defaults.objectForKey(todayViewItemCountKey) as? Int {
                    return preference
                }
            }
            return 7 // default
        }
        set {
            if let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus") {
                defaults.setObject(newValue, forKey: todayViewItemCountKey)
                defaults.synchronize()
            }
        }
    }
    
    /**
        Executes a callback using a list of the user's favorite stop objects.
        Asynchronously obtains the user's location and the user's list of favorite stops.
        Invokes a private function that only executes the user's callback once both operations have completed.
    */
    private static var _updatedLocation: Bool = false
    private static var _userLocation: CLLocation?
    static func favorites(callback: ([BusStop]) -> Void) -> Void {
        
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")
        if defaults == nil {
            println("NSUserDefaults did not instantiate properly in CorvallisBusService")
            return
        }
        let favoriteIds = defaults!.objectForKey("Favorites") as? NSArray ?? NSArray()
        
        locationManagerDelegate.userLocation() {
            self._updatedLocation = true
            self._userLocation = $0
            self._getSortedFavorites(favoriteIds, callback)
        }
        
        self.stops() { stops in
            self._getSortedFavorites(favoriteIds, callback)
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
                if !favorites.any({ $0.id == nearestStop.id }) {
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
        let favoriteIds = NSArray(array: favorites.map() { $0.id })
        if let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus") {
            defaults.setObject(favoriteIds, forKey: "Favorites")
            defaults.synchronize()
        }
    }
    
}