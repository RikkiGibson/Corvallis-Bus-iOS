//
//  BusStopAnnotation.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/31/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

class BusStopAnnotation: NSObject, MKAnnotation {
    let title: String
    let id: Int
    let coordinate: CLLocationCoordinate2D
    var subtitle: String = ""
    
    init(title: String, id: Int, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.id = id
        self.coordinate = coordinate
    }
}
