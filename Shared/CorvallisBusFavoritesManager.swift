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
    static func favoriteStops(stopIds: [Int]) -> Promise<[[String : AnyObject]], BusError> {
        return Promise { completionHandler in
            delegate.userLocation(completionHandler)
        }.map { (location: Failable<CLLocation, BusError>) in
            CorvallisBusAPIClient.favoriteStops(stopIds, location.toOptional()?.coordinate)
        }
    }
    
    // TODO: get user defaults calls out of view controllers as much as possible
    static func cachedFavoriteStops(fallbackToGrayColor: Bool = false) -> [FavoriteStopViewModel] {
        let defaults = NSUserDefaults.groupUserDefaults()
        let cachedFavoriteStops = defaults.cachedFavoriteStops
        return cachedFavoriteStops.mapUnwrap{ toFavoriteStopViewModel($0, fallbackToGrayColor: fallbackToGrayColor) }
    }
}
