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
    private static let BASE_URL = "https://corvallisb.us/api"
    
    static func favoriteStops(stopIds: [Int], _ location: CLLocationCoordinate2D?) -> Promise<[[String : AnyObject]], BusError> {
        let stopsString = stopIds.map{ String($0) }.joinWithSeparator(",")
        let locationString = location == nil ? "" : "\(location!.latitude),\(location!.longitude)"
        let url = NSURL(string: BASE_URL + "/favorites?stops=\(stopsString)&location=\(locationString)")!
        
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONArray)
    }
    
    static func staticData() -> Promise<[String : AnyObject], BusError> {
        let url = NSURL(string: BASE_URL + "/static")!
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONObject)
    }
    
    static func arrivalsSummary(stopIds: [Int]) -> Promise<[String : AnyObject], BusError> {
        guard !stopIds.isEmpty else {
            return Promise { completionHandler in
                completionHandler(.Success([:]))
            }
        }
        
        let joinedStops = stopIds.map{ String($0) }.joinWithSeparator(",")
        let url = NSURL(string: "\(BASE_URL)/arrivals-summary/\(joinedStops)")!
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONObject)
    }
}
