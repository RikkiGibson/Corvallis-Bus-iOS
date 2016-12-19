//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

final class BusRoute : Equatable {
    let name: String
    let color: Color
    let polyline: MKPolyline
    let url: URL
    let path: Set<Int>
    
    init(name: String, color: Color, polyline: MKPolyline, path: Set<Int>, url: URL) {
        self.name = name
        self.color = color
        self.polyline = polyline
        self.path = path
        self.url = url
    }
    
    static func fromDictionary(_ data: [String : AnyObject]) -> BusRoute? {
        guard let name = data["routeNo"] as? String,
            let path = data["path"] as? [Int],
            let polylineString = data["polyline"] as? String,
            let polyline = MKPolyline(gmEncodedString: polylineString),
            let color = parseColor(data["color"]),
            let urlString = data["url"] as? String,
            let url = URL(string: urlString) else {
                return nil
        }
        return BusRoute(name: name, color: color, polyline: polyline, path: Set(path), url: url)
    }
}

func == (lhs: BusRoute, rhs: BusRoute) -> Bool {
    return lhs.name == rhs.name
}
