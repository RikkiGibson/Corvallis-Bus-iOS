//
//  NSUserDefaultsExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/20/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSUserDefaults {
    
    static func groupUserDefaults() -> NSUserDefaults {
        return NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
    }
    
    private static let FAVORITES_KEY = "Favorites"
    var favoriteStopIds: [Int] {
        get {
            return arrayForKey(NSUserDefaults.FAVORITES_KEY) as? [Int] ?? []
        }
        set {
            setObject(newValue, forKey: NSUserDefaults.FAVORITES_KEY)
            synchronize()
        }
    }
    
    private static let NEAREST_STOP_KEY = "shouldShowNearestStop"
    var shouldShowNearestStop: Bool {
        get {
            return objectForKey(NSUserDefaults.NEAREST_STOP_KEY) as? Bool ?? true // default
        }
        set {
            setObject(newValue, forKey: NSUserDefaults.NEAREST_STOP_KEY)
            synchronize()
        }
    }
    
    private static let TODAY_VIEW_ITEM_COUNT_KEY = "todayViewItemCount"
    var todayViewItemCount: Int {
        get {
            return objectForKey(NSUserDefaults.TODAY_VIEW_ITEM_COUNT_KEY) as? Int ?? 7 // default
        }
        set {
            setObject(newValue, forKey: NSUserDefaults.TODAY_VIEW_ITEM_COUNT_KEY)
            synchronize()
        }
    }
    
    private static let CACHED_FAVORITE_STOPS_KEY = "cachedFavoriteStops"
    var cachedFavoriteStops: [[String : AnyObject]] {
        get {
            return objectForKey(NSUserDefaults.CACHED_FAVORITE_STOPS_KEY) as? [[String : AnyObject]] ?? []
        }
        set {
            setObject(newValue, forKey: NSUserDefaults.CACHED_FAVORITE_STOPS_KEY)
            synchronize()
        }
    }
    
    private static let HAS_PREVIOUSLY_LAUNCHED_KEY = "hasPreviouslyLaunched"
    var hasPreviouslyLaunched: Bool {
        get {
            return objectForKey(NSUserDefaults.HAS_PREVIOUSLY_LAUNCHED_KEY) as? Bool ?? false
        }
        set {
            setObject(newValue, forKey: NSUserDefaults.HAS_PREVIOUSLY_LAUNCHED_KEY)
        }
    }
}
