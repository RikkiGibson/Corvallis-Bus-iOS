//
//  StopsMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

class StopsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var initializedMapLocation = false
    var initialStop: BusStop?
    var busAnnotations: [BusStopAnnotation]?
    
    let defaultSpan = MKCoordinateSpanMake(0.01, 0.01)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        CorvallisBusService.stops() { stops in
            dispatch_async(dispatch_get_main_queue()) {
                self.busAnnotations = stops.map() { BusStopAnnotation(stop: $0) }
                self.mapView.addAnnotations(self.busAnnotations)
            }
        }

        /*
        CorvallisBusService.routes() { routes in
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addOverlays(routes.map() { $0.polyline })
            }
        }
        */
        
        self.navigationItem.rightBarButtonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMap:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "refreshMap:",
            userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let authorization = CLLocationManager.authorizationStatus()
        if !self.initializedMapLocation &&
            authorization != .AuthorizedWhenInUse &&
            authorization != .Authorized {
            self.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(44.56802, -123.27926),
                span: MKCoordinateSpanMake(0.028, 0.028)), animated: false)
            self.initializedMapLocation = true
        }
        
        self.refreshMap(self)
    }
    
    func refreshMap(sender: AnyObject) {
        CorvallisBusService.stops() { stops in
            // Opening the view while offline can prevent annotations from being added to the map
            if self.busAnnotations == nil {
                self.busAnnotations = stops.map() { BusStopAnnotation(stop: $0) }
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView.addAnnotations(self.busAnnotations)
                    self.updateFavoritedStateForAllAnnotations()
                    self.displayInitialStop()
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateFavoritedStateForAllAnnotations()
                    if self.initialStop == nil {
                        self.updateArrivalTimeForSelectedAnnotationView()
                    } else {
                        self.displayInitialStop()
                    }
                }
            }
        }
    }
    
    func displayInitialStop() {
        // initialStop is injected by another view in order to display a particular stop on the map
        if self.initialStop != nil && self.busAnnotations != nil {
            let annotation = self.busAnnotations!.first() { $0.stop.id == self.initialStop!.id }
            self.mapView.setRegion(MKCoordinateRegion(center: self.initialStop!.location.coordinate,
                span: self.defaultSpan), animated: false)
            // prevents wonky appearance if this annotation was already selected, but the map was in a different position
            self.mapView.deselectAnnotation(annotation, animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
            self.initializedMapLocation = true
            self.initialStop = nil
        }
    }
    
    
    func updateFavoritedStateForAllAnnotations() {
        CorvallisBusService.favorites() { favorites in
            let favorites = favorites.filter() { !$0.isNearestStop }
            dispatch_async(dispatch_get_main_queue()) {
                for annotation in self.mapView.annotations {
                    if let annotation = annotation as? BusStopAnnotation {
                        self.updateFavoritedStateForAnnotation(annotation, favorites: favorites)
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if !self.initializedMapLocation {
            self.mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate,
                span: self.defaultSpan), animated: false)
            self.initializedMapLocation = true
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.redColor()
            renderer.lineWidth = 5
            return renderer
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            // causes default view to be used for user location
            return nil
        }
        
        let identifier = "MKAnnotationView"
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: identifier) ?? MKAnnotationView()
    
        if let annotation = annotation as? BusStopAnnotation {
            annotationView.canShowCallout = true
            
            let button = UIButton.buttonWithType(UIButtonType.ContactAdd) as UIButton
            button.setImage(UIImage(named: "favorite"), forState: UIControlState.Normal)
            button.setImage(UIImage(named: "favorite"), forState: UIControlState.Selected)
            button.selected = annotation.isFavorite
            
            button.addTarget(self, action: "buttonPush:", forControlEvents: UIControlEvents.TouchUpInside)

            annotationView.rightCalloutAccessoryView = button
            
            updateFavoritedStyleForAnnotationView(annotationView, favorited: annotation.isFavorite)
        }
        
        return annotationView
    }
    
    /**
        Displays the current arrival time on the annotation's callout, updates the favorited state and
        jumps the annotation to the front.
    */
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        updateArrivalTime(view)
    }
    
    func updateArrivalTimeForSelectedAnnotationView() {
        if let selectedAnnotation = self.mapView?.selectedAnnotations?.first as? MKAnnotation {
            if let selectedView = self.mapView.viewForAnnotation(selectedAnnotation) {
                updateArrivalTime(selectedView)
            }
        }
    }
    
    func updateArrivalTime(view: MKAnnotationView) {
        view.layer.zPosition = 2
        
        if let annotation = view.annotation as? BusStopAnnotation {
            CorvallisBusService.arrivals([annotation.stop.id]) { arrivals in
                if let busArrivals = arrivals[annotation.stop.id] {
                    dispatch_async(dispatch_get_main_queue()) {
                        annotation.willChangeValueForKey("subtitle")
                        annotation.subtitle = busArrivals.first?.description ?? "No arrivals!"
                        annotation.didChangeValueForKey("subtitle")
                    }
                }
            }
        }
    }
    
    /**
        When an annotation is deselected, it should jump to the back if it's not a favorite stop.
    */
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        if let annotation = view.annotation as? BusStopAnnotation {
            view.layer.zPosition = annotation.isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
    }
    
    func buttonPush(sender: AnyObject!) {
        if let annotation = self.mapView.selectedAnnotations.first as? BusStopAnnotation {
            let view = self.mapView.viewForAnnotation(annotation)
            CorvallisBusService.favorites() { favorites in
                var favorites = favorites.filter() { !$0.isNearestStop }
                // if this stop is in favorites, remove it
                if favorites.any({ $0.id == annotation.stop.id }) {
                    favorites = favorites.filter() { $0.id != annotation.stop.id }
                } else {
                    // if this stop isn't in favorites, add it
                    favorites.append(annotation.stop)
                }
                CorvallisBusService.setFavorites(favorites)
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateFavoritedStateForAnnotation(annotation, favorites: favorites)
                }
            }
        }
    }
    
    /**
        Updates the image color and button state for an annotation view.
    */
    func updateFavoritedStateForAnnotation(annotation: MKAnnotation, favorites: [BusStop]) {
        if let annotation = annotation as? BusStopAnnotation {
            annotation.isFavorite = favorites.any() { $0.id == annotation.stop.id }
            if let view = self.mapView.viewForAnnotation(annotation) {
                updateFavoritedStyleForAnnotationView(view, favorited: annotation.isFavorite)
            }
        }
    }
    
    func updateFavoritedStyleForAnnotationView(view: MKAnnotationView, favorited: Bool) {
        if let button = view.rightCalloutAccessoryView as? UIButton {
            button.selected = favorited
        }
        if favorited {
            view.image = UIImage(named: "goldoval")
            view.layer.zPosition = 2
        } else {
            view.image = UIImage(named: "greenoval")
            view.layer.zPosition = 1
        }
    }

}
