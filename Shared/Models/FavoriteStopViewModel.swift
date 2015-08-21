//
//  FavoriteStopViewModel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/19/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import UIKit

struct FavoriteStopViewModel {
    let stopName: String
    let stopId: Int
    
    let distanceFromUser: String
    let isNearestStop: Bool
    
    let firstRouteColor: UIColor
    let firstRouteName: String
    let firstRouteArrivals: String
    
    let secondRouteColor: UIColor
    let secondRouteName: String
    let secondRouteArrivals: String
}

func toFavoriteStopViewModel(json: [String: AnyObject], fallbackToGrayColor: Bool) -> FavoriteStopViewModel? {
    guard let stopName = json["StopName"] as? String,
        let stopId = json["StopId"] as? Int,
        let distanceFromUser = json["DistanceFromUser"] as? String,
        let isNearestStop = json["IsNearestStop"] as? Bool,
        let firstRouteName = json["FirstRouteName"] as? String,
        let firstRouteArrivals = json["FirstRouteArrivals"] as? String,
        let secondRouteName = json["SecondRouteName"] as? String,
        let secondRouteArrivals = json["SecondRouteArrivals"] as? String else {
        return nil
    }
    
    let firstRouteColor = parseColor(json["FirstRouteColor"]) ?? (fallbackToGrayColor ? UIColor.lightGrayColor() : UIColor.clearColor())
    let secondRouteColor = parseColor(json["SecondRouteColor"]) ?? UIColor.clearColor()
    
    let result = FavoriteStopViewModel(stopName: stopName, stopId: stopId, distanceFromUser: distanceFromUser, isNearestStop: isNearestStop,
        firstRouteColor: firstRouteColor, firstRouteName: firstRouteName, firstRouteArrivals: firstRouteArrivals,
        secondRouteColor: secondRouteColor, secondRouteName: secondRouteName, secondRouteArrivals: secondRouteArrivals)
    
    return result
}