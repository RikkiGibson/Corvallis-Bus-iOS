//
//  CorvallisBusManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/22/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

struct BusStaticData {
    let stops: [Int : BusStop]
    let routes: [String : BusRoute]
}

private func parseStaticData(json: [String : AnyObject]) -> Failable<BusStaticData, BusError> {
    guard let stopsJSON = json["Stops"] as? [String : [String : AnyObject]],
        let routesJSON = json["Routes"] as? [String : [String : AnyObject]] else {
            return .Error(.NonNotify)
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
    
    return .Success(BusStaticData(stops: stops, routes: routes))
}

private var staticDataCache = CorvallisBusAPIClient.staticData().map(parseStaticData)

class CorvallisBusManager : BusMapViewControllerDataSource {
    
    func staticData() -> Promise<BusStaticData, BusError> {
        if case .Finished(.Error) = staticDataCache.state {
            staticDataCache = CorvallisBusAPIClient.staticData().map(parseStaticData)
        }
        return staticDataCache
    }
    
    // MARK: BusMapViewControllerDataSource
    
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation], BusError> {
        let favoriteIds = NSUserDefaults.groupUserDefaults().favoriteStopIds
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
    func routeDetailsViewModel(stopID: Int) -> Promise<[RouteDetailViewModel], BusError> {
        return CorvallisBusAPIClient.schedule([stopID]).map(parseSchedule)
        .map{ (schedules: StopSchedules) in
            self.staticData().map{ staticData in (staticData, schedules) }
        }.map{ (staticData, schedules) -> Failable<[RouteDetailViewModel], BusError> in
            guard let routeSchedules = schedules[stopID] else {
                return .Error(.NonNotify)
            }
            let sortedRoutes = staticData.routes.values.sort { $0.name < $1.name }
            return .Success(self.toSortedRouteDetailsViewModels(sortedRoutes, routeSchedule: routeSchedules))
        }
    }
    
    func stopDetailsViewModel(stopID: Int) -> Promise<StopDetailViewModel, BusError> {
        let routeDetailsPromise = routeDetailsViewModel(stopID)
        let favoriteStopIDs = NSUserDefaults.groupUserDefaults().favoriteStopIds
        let isFavorite = favoriteStopIDs.contains(stopID)
        return staticData().map { (staticData: BusStaticData) -> Failable<StopDetailViewModel, BusError> in
            guard let stop = staticData.stops[stopID] else {
                return .Error(.NonNotify)
            }
            return .Success(StopDetailViewModel(stopName: stop.name, stopID: stopID, routeDetails: routeDetailsPromise, selectedRouteName: nil, isFavorite: isFavorite))
        }
    }
    
    private func toSortedRouteDetailsViewModels(routes: [BusRoute], routeSchedule: RouteSchedules) -> [RouteDetailViewModel] {
        return routes.mapUnwrap{ (route: BusRoute) -> (route: BusRoute, arrivalTimes: [Int])? in
            if let schedule = routeSchedule[route.name] {
                return (route, schedule)
            } else {
                return nil
            }
        }.sort { first, second in
            first.arrivalTimes.reduce(Int.max, combine: min) <
            second.arrivalTimes.reduce(Int.max, combine: min)
        }.map{ routeTuple in
            RouteDetailViewModel(routeName: routeTuple.route.name, routeColor: routeTuple.route.color,
                arrivalsSummary: toEstimateSummary(routeTuple.arrivalTimes), scheduleSummary: toScheduleSummary(routeTuple.arrivalTimes))
        }
        
    }
}
