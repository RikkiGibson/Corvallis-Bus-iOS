//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

func toBusRoute(data: [String: AnyObject]) -> BusRoute? {
    
    let name = data["Name"] as? String
    if name == nil { return nil }
    
    let additionalName = data["AdditionalName"] as? String
    if additionalName == nil { return nil }
    
    let description = data["Description"] as? String
    if description == nil { return nil }
    
    let path = data["Path"] as? [[String: AnyObject]]
    
    let polyline = MKPolyline(GMEncodedString: data["Polyline"] as? String)
    if polyline == nil { return nil }
    
    let color = parseColor(data["Color"])
    if color == nil { return nil }
    
    return BusRoute(name: name!, additionalName: additionalName!, color: color!,
        routeDescription: description!, polyline: polyline!, path: path)
}

private func parseColor(obj: AnyObject?) -> UIColor? {
    if let string = obj as? String {
        if countElements(string) != 6 { return nil }
        var colorHex: UInt32 = 0
        NSScanner(string: string).scanHexInt(&colorHex)
        return UIColor(red: CGFloat(colorHex >> 16 & 0xFF) / 255.0,
            green: CGFloat(colorHex >> 8 & 0xFF) / 255.0,
            blue: CGFloat(colorHex & 0xFF) / 255.0, alpha: 1.0)
    }
    return nil
}

func == (lhs: BusRoute, rhs: BusRoute) -> Bool {
    return lhs.name == rhs.name
}

class BusRoute : Equatable {
    let name: String
    let additionalName: String
    let color: UIColor
    let routeDescription: String
    let polyline: MKPolyline
    private var _path: [[String: AnyObject]]?
    lazy var path: [Int] = {
        if self._path != nil {
            let result = self._path!.mapUnwrap() { $0["ID"] as? Int }
            self._path = nil // causes deallocation
            return result
        }
        return [Int]()
    }()
    
    private init(name: String, additionalName: String, color: UIColor,
        routeDescription: String, polyline: MKPolyline, path: [[String: AnyObject]]?) {
            self.name = name
            self.additionalName = additionalName
            self.color = color
            self.routeDescription = routeDescription
            self.polyline = polyline
            self._path = path
    }
}