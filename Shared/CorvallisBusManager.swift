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

struct BusStaticData {
    let stops: [Int : BusStop]
    let routes: [String : BusRoute]
}

class CorvallisBusManager : BusMapViewControllerDataSource {
    
    private var staticDataCache: BusStaticData?
    
    private func staticData() -> Promise<BusStaticData> {
        if let staticData = staticDataCache {
            return Promise { completionHandler in
                completionHandler(.Success(staticData))
            }
        }
        return CorvallisBusAPIClient.staticData()
            .map(populateStaticData)
    }
    
    private func populateStaticData(json: [String : AnyObject]) -> Failable<BusStaticData> {
        guard let stopsJSON = json["Stops"] as? [String : [String : AnyObject]],
            let routesJSON = json["Routes"] as? [String : [String : AnyObject]] else {
                return .Error(NSError(domain: "foo", code: 0, userInfo: nil))
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
    
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation]> {
        return staticData().map { staticData in
            return staticData.stops.map{ ($0, BusStopAnnotation(stop: $1)) }
        }
    }
    
    func mapViewModel() -> Promise<BusMapViewModel> {
        return staticData().map { (staticData: BusStaticData) -> BusMapViewModel in
            let annotations = staticData.stops.map{ ($0, BusStopAnnotation(stop: $1)) }
            return BusMapViewModel(stops: annotations, routeArrows: [], routePolyline: nil, selectedStop: nil)

        }
    }
    
    func stopDetailsViewModel(stopID: Int) -> Promise<StopDetailViewModel> {
        return Promise { completionHandler in
            completionHandler(.Success(StopDetailViewModel(stopName: "Test", stopID: 0, routeDetails: [], isFavorite: true)))
        }

        var foo = CorvallisBusAPIClient.schedule([stopID])
            .map{ schedule in parseSchedule(schedule) }
            .map{ (schedule: StopSchedules) -> Promise<(BusStaticData, StopSchedules)> in
            return self.staticData().map{ staticData in (staticData, schedule) }
        }
        // TODO: get static data and schedule, use them to produce a stopdetailviewmodel.
        // how can promises be augmented to concurrently request two resources and continue when both resources come back?
    }
}
