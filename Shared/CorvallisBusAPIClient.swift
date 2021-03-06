//
//  CorvallisBusAPIClient.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import CoreLocation

final class CorvallisBusAPIClient {
    static let BASE_URL = "https://corvallisb.us/api"
    
    static func favoriteStops(_ stopIds: [Int], _ location: CLLocationCoordinate2D?) -> Promise<[[String : AnyObject]], BusError> {
        let stopsString = stopIds.map{ String($0) }.joined(separator: ",")
        let locationString = location == nil ? "" : "\(location!.latitude),\(location!.longitude)"
        let url = URL(string: BASE_URL + "/favorites?stops=\(stopsString)&location=\(locationString)")!
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        return session.downloadData(request)
            .map(JSONSerialization.parseJSONArray)
    }
    
    static func staticData() -> Promise<[String : AnyObject], BusError> {
        let url = URL(string: BASE_URL + "/static")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)

        let session = URLSession.shared
        return session.downloadData(request)
            .map(JSONSerialization.parseJSONObject)
    }
    
    static func arrivalsSummary(_ stopIds: [Int]) -> Promise<[String : AnyObject], BusError> {
        guard !stopIds.isEmpty else {
            return Promise { completionHandler in
                completionHandler(.success([:]))
            }
        }
        
        let joinedStops = stopIds.map{ String($0) }.joined(separator: ",")
        let request = URLRequest(url: URL(string: "\(BASE_URL)/arrivals-summary/\(joinedStops)")!)
        let session = URLSession.shared
        return session.downloadData(request)
            .map(JSONSerialization.parseJSONObject)
    }
    
    static func serviceAlerts() -> Promise<[[String : AnyObject]], BusError> {
        let url = URLRequest(url: URL(string: BASE_URL + "/service-alerts")!)
        let session = URLSession.shared
        return session.downloadData(url)
            .map(JSONSerialization.parseJSONArray)
    }
}
