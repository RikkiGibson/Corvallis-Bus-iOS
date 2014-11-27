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
    var selectedAnnotation: BusStopAnnotation?
    
    let defaultSpan = MKCoordinateSpanMake(0.01, 0.01)
    let greenOvalImage = UIImage(named: "greenoval")
    let goldOvalImage = UIImage(named: "goldoval")
    let favoriteImage = UIImage(named: "favorite")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true

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
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refreshMap:",
            userInfo: nil, repeats: true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshMap(self)
        
        // Give the map a default position when location is disabled
        let authorization = CLLocationManager.authorizationStatus()
        if !self.initializedMapLocation &&
            authorization != .AuthorizedWhenInUse &&
            authorization != .Authorized {
            self.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(44.56802, -123.27926),
                span: MKCoordinateSpanMake(0.028, 0.028)), animated: false)
            self.initializedMapLocation = true
        }
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
            if let height = self.greenOvalImage?.size.height {
                // this tweak makes the bottom of the pin seem to touch the right spot
                annotationView.centerOffset = CGPoint(x: 0, y: height / -3)
            }

            annotationView.canShowCallout = true
            
            let button = UIButton.buttonWithType(.DetailDisclosure) as UIButton
            button.setImage(self.favoriteImage, forState: UIControlState.Normal)
            button.setImage(self.favoriteImage, forState: UIControlState.Selected)
            button.selected = annotation.isFavorite
            
            button.addTarget(self, action: "buttonPush:", forControlEvents: .TouchUpInside)
            
            // weird workaround needed to make the button look right in iOS 8
            button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            button.frame = CGRect(x: 0, y: 0, width: button.frame.width + 20, height: button.frame.height + 20)
            
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
        self.selectedAnnotation = view.annotation as? BusStopAnnotation
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
            annotation.subtitle = "Loading..."
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
        if self.selectedAnnotation != nil {
            view.layer.zPosition = self.selectedAnnotation!.isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
        
        self.selectedAnnotation = nil
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
        Updates the state of an annotation to indicate whether it's a favorite.
    */
    func updateFavoritedStateForAnnotation(annotation: BusStopAnnotation, favorites: [BusStop]) {
        annotation.isFavorite = favorites.any() { $0.id == annotation.stop.id }
        if let view = self.mapView.viewForAnnotation(annotation) {
            updateFavoritedStyleForAnnotationView(view, favorited: annotation.isFavorite)
        }
    }
    
    /**
        Updates the appearance of an annotation view to indicate whether it's a favorite.
    */
    func updateFavoritedStyleForAnnotationView(view: MKAnnotationView, favorited: Bool) {
        if let button = view.rightCalloutAccessoryView as? UIButton {
            button.selected = favorited
        }
        view.image = favorited ? self.goldOvalImage : self.greenOvalImage
        
        var isSelected = false
        if self.selectedAnnotation != nil {
            if let annotationToUpdate = view.annotation as? BusStopAnnotation {
                isSelected = self.selectedAnnotation!.stop.id == annotationToUpdate.stop.id
            }
        }
        
        view.layer.zPosition = favorited || isSelected ? 2 : 1
    }

}
