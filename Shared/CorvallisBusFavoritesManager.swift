//
//  CorvallisBusFavoritesManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/24/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

class CorvallisBusFavoritesManager {
    static let delegate = PromiseLocationManagerDelegate()
    private static func favoriteStops(stopIds: [Int]) -> Promise<[[String: AnyObject]], BusError> {
        return Promise { completionHandler in
            delegate.userLocation(completionHandler)
        }.map { (location: Failable<CLLocation, BusError>) in
            CorvallisBusAPIClient.favoriteStops(stopIds, location.toOptional()?.coordinate)
        }
    }
    
    static func favoriteStopsForApp() -> Promise<[FavoriteStopViewModel], BusError> {
        let defaults = NSUserDefaults.groupUserDefaults()
        let shouldShowNearestStop = defaults.shouldShowNearestStop
        return favoriteStops(defaults.favoriteStopIds)
            .map { (json: [[String: AnyObject]]) -> [FavoriteStopViewModel] in
                let viewModels = json.flatMap{ toFavoriteStopViewModel($0, fallbackToGrayColor: true) }
                let filteredViewModels = shouldShowNearestStop ? viewModels : viewModels.filter{ !$0.isNearestStop }
                return filteredViewModels
            }
    }
    
    /// Performs no filtering, unlike favoriteStopsForApp, because the collapsed state of the widget can change rapidly.
    static func favoriteStopsForWidget() -> Promise<[FavoriteStopViewModel], BusError> {
        let defaults = NSUserDefaults.groupUserDefaults()
        if !hasDisplayableFavorites() {
            defaults.cachedFavoriteStops = []
            return Promise(result: [])
        }
        
        return favoriteStops(defaults.favoriteStopIds)
            .map { (json: [[String: AnyObject]]) -> [FavoriteStopViewModel] in
                defaults.cachedFavoriteStops = json
                let viewModels = json.flatMap{ toFavoriteStopViewModel($0, fallbackToGrayColor: false) }
                return viewModels
            }
    }
    
    static func cachedFavoriteStopsForWidget() -> [FavoriteStopViewModel] {
        let defaults = NSUserDefaults.groupUserDefaults()
        let cachedFavoriteStops = defaults.cachedFavoriteStops
        let viewModels = cachedFavoriteStops.flatMap{
            toFavoriteStopViewModel($0, fallbackToGrayColor: false)
        }
        return viewModels
    }
    
    static func hasDisplayableFavorites() -> Bool {
        let defaults = NSUserDefaults.groupUserDefaults()
        let stopIds = defaults.favoriteStopIds
        
        let locationAvailable = CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
        
        return (locationAvailable && defaults.shouldShowNearestStop) || !stopIds.isEmpty
    }
}
