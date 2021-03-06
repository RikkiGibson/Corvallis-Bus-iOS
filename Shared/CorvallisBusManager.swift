//
//  CorvallisBusManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

struct BusStaticData {
    let obtainedTime: Date
    let stops: [Int : BusStop]
    let routes: [String : BusRoute]
}

private func parseStaticData(_ json: [String : AnyObject]) -> Failable<BusStaticData, BusError> {
    guard let stopsJSON = json["stops"] as? [String : [String : AnyObject]],
        let routesJSON = json["routes"] as? [String : [String : AnyObject]] else {
            return .error(.nonNotify)
    }
    
    let stops = stopsJSON.mapUnwrap {
        (key: String, value: [String : AnyObject]) -> (Int, BusStop)? in
        if let key = Int(key), let stop = BusStop.fromDictionary(value) {
            return (key, stop)
        }
        return nil
    }
    
    let routes = routesJSON.mapUnwrap {
        (key: String, value: [String : AnyObject]) -> (String, BusRoute)? in
        if let route = BusRoute.fromDictionary(value) {
            return (key, route)
        } else {
            return nil
        }
    }
    
    return .success(BusStaticData(obtainedTime: Date(), stops: stops, routes: routes))
}

private var staticDataCache = CorvallisBusAPIClient.staticData().map(parseStaticData)

class CorvallisBusManager : BusMapViewControllerDataSource {
    
    func staticData() -> Promise<BusStaticData, BusError> {
        
        // if there was an error obtaining the static data or it's expired, get it again.
        switch staticDataCache.state {
        case .finished(.success(let staticData)) where !staticData.obtainedTime.isToday():
            fallthrough
        case .finished(.error):
            staticDataCache = CorvallisBusAPIClient.staticData().map(parseStaticData)
        default:
            break
        }
        
        return staticDataCache
    }
    
    // MARK: BusMapViewControllerDataSource
    
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation], BusError> {
        let favoriteIds = UserDefaults.groupUserDefaults().favoriteStopIds
        return staticData().map { staticData in
            return staticData.stops.map{
                let result = ($0, BusStopAnnotation(stop: $1))
                result.1.isFavorite = favoriteIds.contains($0)
                return result
            }
        }
    }
    
    // MARK: StopDetailsViewController support
    
    // TODO: refactor this stuff and remove the stuff that doesn't depend on the instance from the class itself
    func routeDetailsViewModel(_ stopID: Int) -> Promise<[RouteDetailViewModel], BusError> {
        return self.staticData().map { (staticData: BusStaticData) in
            CorvallisBusAPIClient.arrivalsSummary([stopID]).map({ (arrivalsJson: [String: AnyObject]) -> Failable<[RouteDetailViewModel], BusError> in
                guard let stopArrivalsJson = arrivalsJson[String(stopID)] as? [[String: AnyObject]] else { return .error(.nonNotify) }
                return .success(stopArrivalsJson.compactMap({ parseArrivalsSummary($0, routes: staticData.routes) }))
            })
        }
    }
    
    func stopDetailsViewModel(_ stopID: Int) -> Promise<StopDetailViewModel, BusError> {
        let routeDetailsPromise = routeDetailsViewModel(stopID)
        let favoriteStopIDs = UserDefaults.groupUserDefaults().favoriteStopIds
        let isFavorite = favoriteStopIDs.contains(stopID)
        return staticData().map { (staticData: BusStaticData) -> Failable<StopDetailViewModel, BusError> in
            guard let stop = staticData.stops[stopID] else {
                return .error(.nonNotify)
            }
            return .success(StopDetailViewModel(stopName: stop.name, stopID: stopID, routeDetails: routeDetailsPromise, selectedRouteName: nil, isFavorite: isFavorite))
        }
    }
}
