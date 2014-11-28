//
//  StopsMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

class StopsMapViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    private let tableViewHeader = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 22))
    
    private var routesForStopSortedByArrivals: [BusRoute]?
    private var arrivals: [BusArrival]?
    
    @IBOutlet weak var mapView: MKMapView!
    
    var initialStop: BusStop?
    
    private var initializedMapLocation = false
    private var busAnnotations: [BusStopAnnotation]?
    private var selectedAnnotation: BusStopAnnotation?
    
    private let defaultSpan = MKCoordinateSpanMake(0.01, 0.01)
    private let greenOvalImage = UIImage(named: "greenoval")
    private let greenOvalHighlightedImage = UIImage(named: "greenoval-highlighted")
    private let goldOvalImage = UIImage(named: "goldoval")
    private let goldOvalHighlightedImage = UIImage(named: "goldoval-highlighted")
    
    private let favoriteImage = UIImage(named: "favorite")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        self.tableViewHeight.constant = 0
        self.tableView.tableHeaderView = self.tableViewHeader
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
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
        
        // Gives the map a default position when location is disabled
        let authorization = CLLocationManager.authorizationStatus()
        if !self.initializedMapLocation &&
            authorization != .AuthorizedWhenInUse &&
            authorization != .Authorized {
            self.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(44.56802, -123.27926),
                span: MKCoordinateSpanMake(0.028, 0.028)), animated: false)
            self.initializedMapLocation = true
        }
    }
    
    // MARK - Map view delegate
    
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
            if let selectedIndex = self.tableView.indexPathsForSelectedRows()?.first as? NSIndexPath {
                if let currentRoute = self.routesForStopSortedByArrivals?[selectedIndex.row] {
                    renderer.strokeColor = currentRoute.color
                }
            }
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
            
            self.updateStyleForBusAnnotationView(annotationView, favorited: annotation.isFavorite)
        }
        
        return annotationView
    }
    
    func presentTableView() {
        if self.tableViewHeight.constant != 132 {
            self.tableViewHeight.constant = 132
            UIView.animateWithDuration(0.2) { self.view.layoutIfNeeded() }
        }
    }
    
    func dismissTableView() {
        if self.tableViewHeight.constant != 0 {
            self.tableViewHeight.constant = 0
            
            UIView.animateWithDuration(0.2,
                animations: { self.view.layoutIfNeeded() },
                completion: { success in self.tableView.reloadData() })
        }
    }
    
    private var routeListNeedsInitialization = false
    /**
        Displays the current arrival time on the annotation's callout, updates the favorited state and
        jumps the annotation to the front.
    */
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        self.selectedAnnotation = view.annotation as? BusStopAnnotation
        if self.selectedAnnotation != nil {
            self.updateStyleForBusAnnotationView(view, favorited: self.selectedAnnotation!.isFavorite)
        }
        self.routeListNeedsInitialization = true
        self.updateArrivalTime(view)
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
                self.arrivals = arrivals[annotation.stop.id]
                if self.arrivals != nil {
                    self.routesForStopSortedByArrivals = annotation.stop.routesSortedByArrivals(self.arrivals!)
                } else {
                    self.routesForStopSortedByArrivals = nil
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    if self.routeListNeedsInitialization {
                        let firstIndex = NSIndexPath(forRow: 0, inSection: 0)
                        self.tableView.selectRowAtIndexPath(firstIndex, animated: false, scrollPosition: .None)
                        self.tableView(self.tableView, didSelectRowAtIndexPath: firstIndex)
                        
                        self.tableViewHeader.text = annotation.stop.name
                    
                        self.presentTableView()
                        self.routeListNeedsInitialization = false
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
            self.updateStyleForBusAnnotationView(view, favorited: self.selectedAnnotation!.isFavorite)
            view.layer.zPosition = self.selectedAnnotation!.isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
        self.selectedAnnotation = nil
        self.mapView.removeOverlays(self.mapView.overlays)
        
        dispatch_after(50, dispatch_get_main_queue()) {
            if self.selectedAnnotation == nil {
                self.dismissTableView()
            }
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
        Updates the state of an annotation to indicate whether it's a favorite.
    */
    func updateFavoritedStateForAnnotation(annotation: BusStopAnnotation, favorites: [BusStop]) {
        annotation.isFavorite = favorites.any() { $0.id == annotation.stop.id }
        if let view = self.mapView.viewForAnnotation(annotation) {
            self.updateStyleForBusAnnotationView(view, favorited: annotation.isFavorite)
        }
    }
    
    /**
        Updates the appearance of an annotation view to indicate whether it's a favorite.
    */
    func updateStyleForBusAnnotationView(view: MKAnnotationView, favorited: Bool) {
        if let button = view.rightCalloutAccessoryView as? UIButton {
            button.selected = favorited
        }
        
        var isSelected = false
        if self.selectedAnnotation != nil {
            if let annotationToUpdate = view.annotation as? BusStopAnnotation {
                isSelected = self.selectedAnnotation!.stop.id == annotationToUpdate.stop.id
            }
        }
        
        view.layer.zPosition = favorited || isSelected ? 2 : 1
        if favorited {
            view.image = self.goldOvalImage
        } else {
            view.image = self.greenOvalImage
        }
        
    }
    
    // MARK - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.routesForStopSortedByArrivals?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusArrivalCell") as UITableViewCell
        
        if self.arrivals != nil && self.routesForStopSortedByArrivals != nil {
            let currentRoute = self.routesForStopSortedByArrivals![indexPath.row]
            let arrivalsForRoute = self.arrivals!.filter() { $0.route == currentRoute.name }
            let arrivalsDescription = arrivalsForRoute.any() ?
                ", ".join(arrivalsForRoute.map() { $0.friendlyEta }) : "No arrivals!"
            
            cell.textLabel.text = "\(currentRoute.name): \(arrivalsDescription)"
        }
        
        return cell
    }
    
    // MARK - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let currentStop = self.selectedAnnotation?.stop {
            let currentRoute = currentStop.routes[indexPath.row]
            self.mapView.addOverlay(currentRoute.polyline)
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.mapView.removeOverlays(self.mapView.overlays)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
