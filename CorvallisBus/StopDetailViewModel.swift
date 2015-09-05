//
//  StopDetailViewModel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

struct RouteDetailViewModel {
    let routeName: String
    let routeColor: UIColor
    let arrivalsSummary: String
    let scheduleSummary: String
}

struct StopDetailViewModel {
    let stopName: String
    let stopID: Int?
    var routeDetails: Promise<[RouteDetailViewModel], BusError>
    var isFavorite: Bool
    
    static func defaultViewModel() -> StopDetailViewModel {
        return StopDetailViewModel(stopName: "", stopID: nil, routeDetails: Promise(result: []), isFavorite: false)
    }
}
