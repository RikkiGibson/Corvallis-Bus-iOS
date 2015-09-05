//
//  BusRoute.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

final class BusRoute : Equatable {
    let name: String
    let color: UIColor
    let polyline: MKPolyline
    let url: NSURL
    let path: Set<Int>
    
    init(name: String, color: UIColor, polyline: MKPolyline, path: Set<Int>, url: NSURL) {
        self.name = name
        self.color = color
        self.polyline = polyline
        self.path = path
        self.url = url
    }
    
    static func fromDictionary(data: [String : AnyObject]) -> BusRoute? {
        guard let name = data["RouteNo"] as? String,
            let path = data["Path"] as? [Int],
            let polylineString = data["Polyline"] as? String,
            let polyline = MKPolyline(GMEncodedString: polylineString),
            let color = parseColor(data["Color"]),
            let urlString = data["Url"] as? String,
            let url = NSURL(string: urlString) else {
                return nil
        }
        return BusRoute(name: name, color: color, polyline: polyline, path: Set(path), url: url)
    }
    
    lazy var arrows: [ArrowAnnotation] = {
        var arrows = [ArrowAnnotation]()
        
        var pointer = self.polyline.points()
        
        for var i = 0; i < self.polyline.pointCount - 1; i += 10 {
            let firstPoint = pointer[i]
            let secondPoint = pointer[i+1]
            
            let dy = secondPoint.y - firstPoint.y
            let dx = secondPoint.x - firstPoint.x
            
            // M_PI / 4 is added because the arrow graphic is facing
            // at that angle to the positive X axis to begin with
            let angle = atan2(dy, dx) + M_PI / 4
            arrows.append(ArrowAnnotation(mapPoint: firstPoint, angle: angle))
        }
        
        return arrows
    }()
}

func == (lhs: BusRoute, rhs: BusRoute) -> Bool {
    return lhs.name == rhs.name
}

final class ArrowAnnotation : NSObject, MKAnnotation {
    let angle: CGFloat
    let coordinate: CLLocationCoordinate2D
    
    init(mapPoint: MKMapPoint, angle: Double) {
        self.coordinate = MKCoordinateForMapPoint(mapPoint)
        self.angle = CGFloat(angle)
    }
}