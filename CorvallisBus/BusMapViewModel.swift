//
//  BusMapViewModel.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

struct BusMapViewModel {
    var stops: [Int : BusStopAnnotation]
    var routeArrows: [ArrowAnnotation]
    var routePolyline: MKPolyline?
    var selectedStop: BusStopAnnotation?
}
