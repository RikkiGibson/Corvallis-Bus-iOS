//
//  CorvallisBusLocationManagerDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class PromiseLocationManagerDelegate : NSObject, CLLocationManagerDelegate {
    private let _locationManager = CLLocationManager()
    private var _callback: Failable<CLLocation, BusError> -> Void = { loc in }
    
    override init() {
        super.init()
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager.requestWhenInUseAuthorization()
        _locationManager.delegate = self
    }
    
    func userLocation(callback: Failable<CLLocation, BusError> -> Void) {
        _callback = callback
        _locationManager.startUpdatingLocation()
    }
    
    // MARK - location manager delegate
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        _locationManager.stopUpdatingLocation()
        
        _callback(.Success(locations.last!))
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        _callback(.Error(BusError.fromNSError(error)))
    }
}
