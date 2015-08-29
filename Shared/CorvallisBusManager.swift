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

class CorvallisBusManager : BusMapViewControllerDataSource {
    
    private var staticDataCache: BusStaticData?
    
    private func staticData() -> Promise<BusStaticData, BusError> {
        if let staticData = staticDataCache {
            return Promise { completionHandler in
                completionHandler(.Success(staticData))
            }
        }
        return CorvallisBusAPIClient.staticData()
            .map(populateStaticData)
    }
    
    private func populateStaticData(json: [String : AnyObject]) -> Failable<BusStaticData, BusError> {
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
        
        staticDataCache = BusStaticData(stops: stops, routes: routes)
        return .Success(staticDataCache!)
    }
    
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
    
    func mapViewModel() -> Promise<BusMapViewModel, BusError> {
        return staticData().map { (staticData: BusStaticData) -> BusMapViewModel in
            let annotations = staticData.stops.map{ ($0, BusStopAnnotation(stop: $1)) }
            return BusMapViewModel(stops: annotations, routeArrows: [], routePolyline: nil, selectedStop: nil)

        }
    }
    
    func stopDetailsViewModel(stopID: Int) -> Promise<StopDetailViewModel, BusError> {
        return CorvallisBusAPIClient.schedule([stopID]).map(parseSchedule)
        .map{ schedules in
            self.staticData().map{ staticData in (staticData, schedules) }
        }.map{ (staticData, schedules) in
            self.toStopDetailsViewModel(stopID, staticData: staticData, schedules: schedules)
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
    
    private func toStopDetailsViewModel(stopID: Int, staticData: BusStaticData, schedules: StopSchedules) -> Failable<StopDetailViewModel, BusError> {
        guard let stop = staticData.stops[stopID],
            let routeSchedules = schedules[stopID] else {
                return .Error(.NonNotify)
        }
        
        let isFavorite = NSUserDefaults.groupUserDefaults().favoriteStopIds.contains(stopID)
        
        let sortedRoutes = staticData.routes.values.sort{ $0.name < $1.name }
        let routeDetails = toSortedRouteDetailsViewModels(sortedRoutes, routeSchedule: routeSchedules)
        return .Success(StopDetailViewModel(stopName: stop.name, stopID: stopID, routeDetails: routeDetails, isFavorite: isFavorite))
    }
}
