//
//  FavoriteStopViewModel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/19/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

#if os(iOS)
    import UIKit
    typealias Color = UIColor
#else
    import Cocoa
    typealias Color = NSColor
#endif

struct FavoriteStopViewModel {
    let stopName: String
    let stopId: Int
    
    let distanceFromUser: String
    let isNearestStop: Bool
    
    let firstRouteColor: Color
    let firstRouteName: String
    let firstRouteArrivals: String
    
    let secondRouteColor: Color
    let secondRouteName: String
    let secondRouteArrivals: String
    
    static func empty() -> FavoriteStopViewModel {
        return FavoriteStopViewModel(stopName: "", stopId: 0, distanceFromUser: "", isNearestStop: false, firstRouteColor: Color.clear, firstRouteName: "", firstRouteArrivals: "", secondRouteColor: Color.clear, secondRouteName: "", secondRouteArrivals: "")
    }
}

func toFavoriteStopViewModel(_ json: [String: AnyObject]) -> FavoriteStopViewModel? {
    guard let stopName = json["stopName"] as? String,
        let stopId = json["stopID"] as? Int,
        let distanceFromUser = json["distanceFromUser"] as? String,
        let isNearestStop = json["isNearestStop"] as? Bool,
        let firstRouteName = json["firstRouteName"] as? String,
        let firstRouteArrivals = json["firstRouteArrivals"] as? String,
        let secondRouteName = json["secondRouteName"] as? String,
        let secondRouteArrivals = json["secondRouteArrivals"] as? String else {
        return nil
    }
    
    let firstRouteColor = parseColor(json["firstRouteColor"]) ?? Color.lightGray
    let secondRouteColor = parseColor(json["secondRouteColor"]) ?? Color.clear
    
    let result = FavoriteStopViewModel(stopName: stopName, stopId: stopId, distanceFromUser: distanceFromUser, isNearestStop: isNearestStop,
        firstRouteColor: firstRouteColor, firstRouteName: firstRouteName, firstRouteArrivals: firstRouteArrivals,
        secondRouteColor: secondRouteColor, secondRouteName: secondRouteName, secondRouteArrivals: secondRouteArrivals)
    
    return result
}
