//
//  NSUserDefaultsExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/20/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

//static func setFavorites(favorites: [BusStop]) -> Void {
//    let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
//    let favoriteIds = NSArray(array: favorites.map() { $0.id })
//    defaults.setObject(favoriteIds, forKey: "Favorites")
//    defaults.synchronize()
//}

extension NSUserDefaults {
    static let FAVORITES_KEY = "Favorites"
    
    static func getAppUserDefaults() -> NSUserDefaults {
        return NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
    }
    
    func getFavoriteStopIds() -> [Int] {
        return arrayForKey(NSUserDefaults.FAVORITES_KEY) as? [Int] ?? [Int]()
    }
    
    func setFavoriteStopIds(stopIds: [Int]) {
        setObject(stopIds, forKey: NSUserDefaults.FAVORITES_KEY)
    }
}