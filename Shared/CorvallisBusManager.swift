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

class CorvallisBusManager {
    
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
        guard let stopsJSON = json["Stops"] as? [Int: [String : AnyObject]],
            let routesJSON = json["Routes"] as? [String : [String : AnyObject]] else {
                return .Error(NSError(domain: "foo", code: 0, userInfo: nil))
        }
        
        let stops = stopsJSON.mapUnwrap {
            (key: Int, value: [String : AnyObject]) -> (Int, BusStop)? in
            if let stop = BusStop.fromDictionary(value) {
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
    
    func mapViewModel() -> Promise<BusMapViewModel> {
        return staticData().map { (staticData: BusStaticData) -> BusMapViewModel in
            let annotations = staticData.stops.map{ ($0, BusStopAnnotation(stop: $1)) }
            return BusMapViewModel(stops: annotations, routeArrows: [], routePolyline: nil, selectedStop: nil)

        }
    }
}
