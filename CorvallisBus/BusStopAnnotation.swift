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
    let stop: BusStop
    
    var title: String { get { return stop.name } }
    var coordinate: CLLocationCoordinate2D { get { return stop.location.coordinate } }
    
    var subtitle: String { get { return stop.id.description } }
    var isFavorite = false
    
    init(stop: BusStop) {
        self.stop = stop
    }
}
