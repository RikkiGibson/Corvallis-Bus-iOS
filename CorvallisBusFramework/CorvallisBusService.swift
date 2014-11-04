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
    static func stops(callback: ([BusStop]) -> Void) -> Void {
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
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("stops") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                    }
                    
                    self._stops = stopJson.mapUnwrap() { BusStop(data: $0) }
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
                    }
                    
                    var jsonError: NSError?
                    var stopJson = NSJSONSerialization.JSONObjectWithData(data,
                        options: .AllowFragments,
                        error: &jsonError)?.objectForKey("routes") as NSArray as [[String : AnyObject]]
                    
                    if (jsonError != nil) {
                        println(jsonError!.description)
                    }
                    
                    self._routes = stopJson.mapUnwrap() { BusRoute(data: $0) }
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
    static func arrivals(stops: [Int], callback: [Int : [BusArrival]] -> Void) -> Void {
        var joinedStops = ",".join(stops.map() { String($0) })
        var urlString = "\(rootUrl)/arrivals?stops=\(joinedStops)"
        var url = NSURL(string: "\(rootUrl)/arrivals?stops=\(joinedStops)")
        
        if url == nil {
            println("NSURL did not instantiate properly")
            return
        }
        
        var session = NSURLSession.sharedSession();
        session.dataTaskWithURL(url!, completionHandler: {
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
    
    /**
        Executes a callback using a list of the user's favorite stop objects.
        Asynchronously obtains the user's location and the user's list of favorite stops.
        Invokes a private function that only executes the user's callback once both operations have completed.
    */
    private static var _userLocation: CLLocation?
    private static var _favorites: [BusStop]?
    static func favorites(callback: ([BusStop]) -> Void) -> Void {
        locationManagerDelegate.userLocation() {
            self._userLocation = $0
            self._getSortedFavorites(callback)
        }
        
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")
        if defaults == nil {
            println("NSUserDefaults did not instantiate properly in CorvallisBusService")
            return
        }
        let favoriteIds = defaults!.objectForKey("Favorites") as? NSArray ?? NSArray()
        
        self.stops() { stops in
            self._favorites = stops.filter() { stop in favoriteIds.containsObject(stop.id) }
            self._getSortedFavorites(callback)
        }
    }
    
    /**
        Finally executes the client's callback with the sorted list of favorites.
    */
    private static func _getSortedFavorites(callback: [BusStop] -> Void) -> Void {
        if self._favorites == nil || self._userLocation == nil {
            return
        }
        var favorites = self._favorites!
        for favorite in favorites {
            favorite.distanceFromUser = favorite.location.distanceFromLocation(self._userLocation!)
        }
        favorites.sort() { $0.distanceFromUser < $1.distanceFromUser }
        
        self._userLocation = nil
        self._favorites = nil
        
        callback(favorites)
    }
    
    static func setFavorites(favorites: [BusStop]) -> Void {
        let favoriteIds = NSArray(array: favorites.map() { $0.id })
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")
        
        if defaults == nil {
            println("NSUserDefaults did not instantiate properly in CorvallisBusService")
            return
        }
        
        defaults!.setObject(favoriteIds, forKey: "Favorites")
        defaults!.synchronize()
    }
    
}