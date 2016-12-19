//
//  StopDetailViewModel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

/// Represents a row in the stop details table.
struct RouteDetailViewModel {
    let routeName: String
    let routeColor: Color
    let arrivalsSummary: String
    let scheduleSummary: String
}

func parseArrivalsSummary(_ json: [String: AnyObject], routes: [String: BusRoute]) -> RouteDetailViewModel? {
    guard let routeName = json["routeName"] as? String,
        let routeColor = routes[routeName]?.color,
        let arrivalsSummary = json["arrivalsSummary"] as? String,
        let scheduleSummary = json["scheduleSummary"] as? String else {
            return nil
    }
    return RouteDetailViewModel(routeName: routeName, routeColor: routeColor,
        arrivalsSummary: arrivalsSummary, scheduleSummary: scheduleSummary)
}

/// Represents the whole contents of the stop details table.
struct StopDetailViewModel {
    let stopName: String
    let stopID: Int?
    var routeDetails: Promise<[RouteDetailViewModel], BusError>
    var selectedRouteName: String?
    var isFavorite: Bool
    
    static func empty() -> StopDetailViewModel {
        return StopDetailViewModel(stopName: "", stopID: nil, routeDetails: Promise(result: []), selectedRouteName: nil, isFavorite: false)
    }
}
