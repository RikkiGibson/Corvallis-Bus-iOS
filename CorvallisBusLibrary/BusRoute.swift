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
    
    let path = data["Path"] as? [[String: AnyObject]]
    
    let polyline = MKPolyline(GMEncodedString: data["Polyline"] as? String) ?? MKPolyline()
    
    let color = parseColor(data["Color"]) ?? UIColor(red: 115/255, green: 160/255, blue: 160/255, alpha: 1)
    
    var URL: NSURL?
    if let urlString = data["URL"] as? String {
        URL = NSURL(string: urlString)
    }
    URL = URL ?? NSURL(string: "http://www.corvallisoregon.gov/index.aspx?page=167")
    
    return BusRoute(name: name!, color: color, polyline: polyline, path: path, url: URL!)
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
    let color: UIColor
    let polyline: MKPolyline
    let url: NSURL
    private var _path: [[String: AnyObject]]?
    lazy var path: [Int] = {
        if self._path != nil {
            let result = self._path!.mapUnwrap() { $0["ID"] as? Int }
            self._path = nil // causes deallocation
            return result
        }
        return [Int]()
    }()
    
    private init(name: String, color: UIColor, polyline: MKPolyline, path: [[String: AnyObject]]?, url: NSURL) {
            self.name = name
            self.color = color
            self.polyline = polyline
            self._path = path
            self.url = url
    }
}