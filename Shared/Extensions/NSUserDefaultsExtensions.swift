//
//  NSUserDefaultsExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/20/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    static func groupUserDefaults() -> UserDefaults {
        return UserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
    }
    
    private static let FAVORITES_KEY = "Favorites"
    var favoriteStopIds: [Int] {
        get {
            return array(forKey: UserDefaults.FAVORITES_KEY) as? [Int] ?? []
        }
        set {
            set(newValue, forKey: UserDefaults.FAVORITES_KEY)
            synchronize()
        }
    }
    
    private static let NEAREST_STOP_KEY = "shouldShowNearestStop"
    var shouldShowNearestStop: Bool {
        get {
            return object(forKey: UserDefaults.NEAREST_STOP_KEY) as? Bool ?? true
        }
        set {
            set(newValue, forKey: UserDefaults.NEAREST_STOP_KEY)
            synchronize()
        }
    }
    
    private static let TODAY_VIEW_ITEM_COUNT_KEY = "todayViewItemCount"
    var todayViewItemCount: Int {
        get {
            let storedValue = object(forKey: UserDefaults.TODAY_VIEW_ITEM_COUNT_KEY) as? Int ?? 2
            let minimum: Int
            if #available(iOS 10, *) {
                minimum = 2
            } else {
                minimum = 1
            }
            // Set lower and upper bounds for today view item count
            return max(minimum, min(7, storedValue))
        }
        set {
            set(newValue, forKey: UserDefaults.TODAY_VIEW_ITEM_COUNT_KEY)
            synchronize()
        }
    }
    
    private static let CACHED_FAVORITE_STOPS_KEY = "cachedFavoriteStops"
    var cachedFavoriteStops: [[String : AnyObject]] {
        get {
            return object(forKey: UserDefaults.CACHED_FAVORITE_STOPS_KEY) as? [[String : AnyObject]] ?? []
        }
        set {
            set(newValue, forKey: UserDefaults.CACHED_FAVORITE_STOPS_KEY)
            synchronize()
        }
    }
    
    private static let HAS_PREVIOUSLY_LAUNCHED_KEY = "hasPreviouslyLaunched"
    var hasPreviouslyLaunched: Bool {
        get {
            return object(forKey: UserDefaults.HAS_PREVIOUSLY_LAUNCHED_KEY) as? Bool ?? false
        }
        set {
            set(newValue, forKey: UserDefaults.HAS_PREVIOUSLY_LAUNCHED_KEY)
        }
    }
    
    
    private static let SEEN_SERVICE_ALERT_IDS = "seenServiceAlertIds"
    var seenServiceAlertIds: Set<String> {
        get {
            let arr = object(forKey: UserDefaults.SEEN_SERVICE_ALERT_IDS) as? [String] ?? []
            return Set(arr)
        }
        set {
            let arr = Array(newValue)
            set(arr, forKey: UserDefaults.SEEN_SERVICE_ALERT_IDS)
        }
    }
}
