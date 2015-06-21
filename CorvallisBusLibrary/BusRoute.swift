//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

let DEFAULT_ROUTE_COLOR = UIColor(red: 115/255, green: 160/255, blue: 160/255, alpha: 1)
func toBusRoute(data: [String: AnyObject]) -> BusRoute? {
    if let name = data["Name"] as? String {
        let path = data["Path"] as? [AnyObject]
        let polyline = MKPolyline(GMEncodedString: data["Polyline"] as? String) ?? MKPolyline()
        let color = parseColor(data["Color"]) ?? DEFAULT_ROUTE_COLOR
        
        let URL: NSURL
        if let urlString = data["URL"] as? String, let maybeURL = NSURL(string: urlString) {
            URL = maybeURL
        } else {
            URL = NSURL(string: "http://www.corvallisoregon.gov/index.aspx?page=167")!
        }
        
        return BusRoute(name: name, color: color, polyline: polyline, path: path, url: URL)
    } else {
        return nil
    }
    
}

private func parseColor(obj: AnyObject?) -> UIColor? {
    if let colorString = obj as? String where count(colorString) == 6 {
        var colorHex: UInt32 = 0
        NSScanner(string: colorString).scanHexInt(&colorHex)
        return UIColor(red: CGFloat(colorHex >> 16 & 0xFF) / 255.0,
            green: CGFloat(colorHex >> 8 & 0xFF) / 255.0,
            blue: CGFloat(colorHex & 0xFF) / 255.0, alpha: 1.0)
    } else {
        return nil
    }
}

func == (lhs: BusRoute, rhs: BusRoute) -> Bool {
    return lhs.name == rhs.name
}

final class BusRoute : Equatable {
    let name: String
    let color: UIColor
    let polyline: MKPolyline
    let url: NSURL
    private var _path: [AnyObject]?
    lazy var path: [Int] = {
        if let stopIDs = self._path?.mapUnwrap({ $0 as? Int }) {
            self._path = nil // causes deallocation
            return stopIDs
        } else {
            return [Int]()
        }
    }()
    
    private init(name: String, color: UIColor, polyline: MKPolyline,
        path: [AnyObject]?, url: NSURL) {
            self.name = name
            self.color = color
            self.polyline = polyline
            self._path = path
            self.url = url
            
    }
    
    lazy var arrows: [ArrowAnnotation] = {
        var arrows = [ArrowAnnotation]()
        
        var pointer = self.polyline.points()
        
        for var i = 0; i < self.polyline.pointCount - 1; i += 10 {
            let firstPoint = pointer[i]
            let secondPoint = pointer[i+1]
            
            let dy = secondPoint.y - firstPoint.y
            let dx = secondPoint.x - firstPoint.x
            
            let angle = atan2(dy, dx) + M_PI / 4
            arrows.append(ArrowAnnotation(mapPoint: firstPoint, angle: angle))
        }
        
        return arrows
    }()
}

final class ArrowAnnotation : NSObject, MKAnnotation {
    var angle: CGFloat
    var coordinate: CLLocationCoordinate2D
    
    override init() {
        angle = 0.0
        coordinate = CLLocationCoordinate2D()
    }
    
    init(mapPoint: MKMapPoint, angle: Double) {
        self.coordinate = MKCoordinateForMapPoint(mapPoint)
        self.angle = CGFloat(angle)
    }
}