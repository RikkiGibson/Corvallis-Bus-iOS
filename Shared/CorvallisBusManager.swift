//
//  CorvallisBusManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

// called by view controller
// gets user defaults, location, calls webclient, and optionally transforms results
// is the existence of this thing justified?

class CorvallisBusManager {
    static let locationManagerDelegate = CorvallisBusLocationManagerDelegate()
    
    static func getFavoriteStops(stopIds: [Int]) -> Promise<[[String : AnyObject]]> {
        
        return Promise(locationManagerDelegate.userLocation)
            .map { (location: Failable<CLLocation>) in
                CorvallisBusClient.getFavoriteStops(stopIds, location.toOptional()?.coordinate)
            }
    }
}