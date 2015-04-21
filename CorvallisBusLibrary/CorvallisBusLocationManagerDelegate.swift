//
//  CorvallisBusLocationManagerDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import CoreLocation

final class CorvallisBusLocationManagerDelegate : NSObject, CLLocationManagerDelegate {
    private let _locationManager = CLLocationManager()
    private var _callback: Failable<CLLocation> -> Void = { loc in }
    
    override init() {
        super.init()
        self._locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // iOS 8 only
        if self._locationManager.respondsToSelector("requestWhenInUseAuthorization") {
            self._locationManager.requestWhenInUseAuthorization()
        }
        
        self._locationManager.delegate = self
    }
    
    func userLocation(callback: Failable<CLLocation> -> Void) {
        self._callback = callback
        _locationManager.startUpdatingLocation()
    }
    
    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        _locationManager.stopUpdatingLocation()
        
        let location = locations.last as! CLLocation
        _callback(.Success(Box(location)))
        
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        _callback(.Error(error))
    }
}