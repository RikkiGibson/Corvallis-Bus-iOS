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
        let viewModelsPromise = favoriteStops(defaults.favoriteStopIds)
            .map { (json: [[String: AnyObject]]) -> [FavoriteStopViewModel] in
                let viewModels = json.flatMap{ toFavoriteStopViewModel($0, fallbackToGrayColor: true) }
                if !defaults.shouldShowNearestStop {
                    return viewModels.filter({ !$0.isNearestStop })
                }
                return viewModels
        }
        return viewModelsPromise
    }
    
    private static func filterFavoriteStopsForWidget(viewModels: [FavoriteStopViewModel],
        _ defaults: NSUserDefaults) -> [FavoriteStopViewModel]
    {
        let filteredModels = defaults.shouldShowNearestStop
            ? viewModels
            : viewModels.filter({ !$0.isNearestStop })
        
        return filteredModels.limit(defaults.todayViewItemCount)
    }
    
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
                return filterFavoriteStopsForWidget(viewModels, defaults)
            }
    }
    
    static func cachedFavoriteStopsForWidget() -> [FavoriteStopViewModel] {
        let defaults = NSUserDefaults.groupUserDefaults()
        let viewModels = defaults.cachedFavoriteStops.flatMap({
            toFavoriteStopViewModel($0, fallbackToGrayColor: false)
        })
        return filterFavoriteStopsForWidget(viewModels, defaults)
    }
    
    static func hasDisplayableFavorites() -> Bool {
        let defaults = NSUserDefaults.groupUserDefaults()
        let stopIds = defaults.favoriteStopIds
        
        if !stopIds.isEmpty {
            return true
        }
        
        if !defaults.shouldShowNearestStop {
            return false
        }
        
        let locationAvailable = CLLocationManager.locationServicesEnabled() &&
            CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
        
        return locationAvailable
    }
}
