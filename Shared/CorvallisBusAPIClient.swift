//
//  CorvallisBusAPIClient.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

final class CorvallisBusAPIClient {
    private static let BASE_URL = "http://corvallisbus.azurewebsites.net"
    
    static func favoriteStops(stopIds: [Int], _ location: CLLocationCoordinate2D?) -> Promise<[[String : AnyObject]]> {
        let stopsString = ",".join(stopIds.map{ String($0) })
        let locationString = location == nil ? "" : "\(location!.latitude),\(location!.longitude)"
        let url = NSURL(string: BASE_URL + "/favorites?stops=\(stopsString)&location=\(locationString)")!
        
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONArray)
    }
    
    static func staticData() -> Promise<[String : AnyObject]> {
        let url = NSURL(string: BASE_URL + "/static")!
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONObject)
    }
    
    static func schedule(stopIds: [Int]) -> Promise<[String : AnyObject]> {
        guard stopIds.count != 0 else {
            return Promise { completionHandler in
                completionHandler(.Success([:]))
            }
        }
        let joinedStops = ",".join(stopIds.map{ String($0) })
        let url = NSURL(string: BASE_URL + "/schedule/" + joinedStops)!
        let session = NSURLSession.sharedSession()
        return session.downloadData(url)
            .map(NSJSONSerialization.parseJSONObject)
        
    }
}
