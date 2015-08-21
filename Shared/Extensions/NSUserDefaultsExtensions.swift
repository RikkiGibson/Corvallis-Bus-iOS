//
//  NSUserDefaultsExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/20/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSUserDefaults {
    
    static func appUserDefaults() -> NSUserDefaults {
        return NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")!
    }
    
    private static let FAVORITES_KEY = "Favorites"
    var favoriteStopIds: [Int] {
        get {
            return arrayForKey(NSUserDefaults.FAVORITES_KEY) as? [Int] ?? [Int]()
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
}