//
//  CorvallisBusFavoritesManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/24/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

class CorvallisBusFavoritesManager {
    static let delegate = PromiseLocationManagerDelegate()
    static func favoriteStops(updateCache shouldUpdateCache: Bool, fallbackToGrayColor: Bool, limitResults: Bool) -> Promise<[FavoriteStopViewModel], BusError> {
        let defaults = NSUserDefaults.groupUserDefaults()
        let stopIds = defaults.favoriteStopIds
        let shouldShowNearestStop = defaults.shouldShowNearestStop
        
        return Promise { completionHandler in
            delegate.userLocation(completionHandler)
        }.map { (location: Failable<CLLocation, BusError>) in
            CorvallisBusAPIClient.favoriteStops(stopIds, location.toOptional()?.coordinate)
        }.map { (json: [[String: AnyObject]]) -> [FavoriteStopViewModel] in
            if shouldUpdateCache {
                defaults.cachedFavoriteStops = json
            }
            let viewModels = json.flatMap{ toFavoriteStopViewModel($0, fallbackToGrayColor: fallbackToGrayColor) }
            let filteredViewModels = shouldShowNearestStop ? viewModels : viewModels.filter{ !$0.isNearestStop }
            return limitResults ? filteredViewModels.limit(defaults.todayViewItemCount) : filteredViewModels
        }
    }
    
    static func cachedFavoriteStops(fallbackToGrayColor fallbackToGrayColor: Bool) -> [FavoriteStopViewModel] {
        let defaults = NSUserDefaults.groupUserDefaults()
        let limit = defaults.todayViewItemCount
        let cachedFavoriteStops = defaults.cachedFavoriteStops
        
        return cachedFavoriteStops.flatMap{
            toFavoriteStopViewModel($0, fallbackToGrayColor: fallbackToGrayColor)
        }.limit(limit)
    }
}
