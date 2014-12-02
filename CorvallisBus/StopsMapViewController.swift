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
    @IBOutlet weak var tableViewHeader: UILabel!
    
    // DON'T QUESTION MY METHODS
    private let TABLE_VIEW_HEIGHT: CGFloat = {
        let deviceHeight = UIScreen.mainScreen().bounds.height
        var tableViewHeight = CGFloat(22.0)
        while tableViewHeight / deviceHeight < 0.28 {
            tableViewHeight += 44
        }
        return CGFloat(tableViewHeight)
    }()
    
    let CORVALLIS_LOCATION = CLLocation(latitude: 44.56802, longitude: -123.27926)
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
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
        
        self.mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate,
            span: MKCoordinateSpanMake(0.04, 0.04)), animated: false)
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        self.tableViewHeight.constant = 0
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
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
    }
    
    // MARK - Map view delegate
    
    func refreshMap(sender: AnyObject) {
        let authorization = CLLocationManager.authorizationStatus()
        
        self.locationButton.hidden =
            authorization != .AuthorizedWhenInUse &&
            authorization != .Authorized
        
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
        if self.initialStop != nil {
            
            if let annotation = self.busAnnotations?.first({ $0.stop.id == self.initialStop!.id }) {
                
                self.mapView.setRegion(MKCoordinateRegion(center: self.initialStop!.location.coordinate,
                    span: self.defaultSpan), animated: true)
                
                // prevents wonky appearance if this annotation was already selected, but the map was in a different position
                self.mapView.deselectAnnotation(annotation, animated: true)
                self.mapView.selectAnnotation(annotation, animated: true)
            }
            
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
            // If the user is more than roughly 20 miles from Corvallis, don't go to their location
            if userLocation.location.distanceFromLocation(CORVALLIS_LOCATION) < 32000 {
                self.mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate,
                    span: self.defaultSpan), animated: true)
            }
            self.initializedMapLocation = true
        }
    }
    
    @IBAction func goToUserLocation(sender: AnyObject) {
        self.mapView.setCenterCoordinate(self.mapView.userLocation.location.coordinate, animated: true)
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
            
            self.updateStyleForBusAnnotationView(annotationView, favorited: annotation.isFavorite)
        }
        
        return annotationView
    }
    
    func presentTableView(#animated: Bool) {
        if self.tableViewHeight.constant != self.TABLE_VIEW_HEIGHT {
            self.tableViewHeight.constant = self.TABLE_VIEW_HEIGHT
            if animated {
                UIView.animateWithDuration(0.2) { self.view.layoutIfNeeded() }
            } else {
                self.view.layoutIfNeeded()
            }
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
            
            self.favoriteButton.selected = self.selectedAnnotation!.isFavorite
            self.tableViewHeader.text = self.selectedAnnotation!.stop.name
            self.presentTableView(animated: true)
        }
        self.routeListNeedsInitialization = true
        self.updateArrivalTime(view)
    }
    
    func updateArrivalTimeForSelectedAnnotationView() {
        if let selectedAnnotation = self.mapView?.selectedAnnotations?.first as? BusStopAnnotation {
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
                dispatch_async(dispatch_get_main_queue(), self.updateTableView)
            }
        }
    }
    
    func updateTableView() {
        // TODO: select the row containing the route that was selected before
        // reloading to preserve consistency between the map and table view.
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        if self.routeListNeedsInitialization {
            let firstIndex = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.selectRowAtIndexPath(firstIndex, animated: false, scrollPosition: .None)
            self.tableView(self.tableView, didSelectRowAtIndexPath: firstIndex)
            
            self.routeListNeedsInitialization = false
        }
    }
    
    /**
        When an annotation is deselected, it should jump to the back if it's not a favorite stop.
    */
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        if self.selectedAnnotation != nil {
            let isFavorite = self.selectedAnnotation!.isFavorite
            self.selectedAnnotation = nil
            self.updateStyleForBusAnnotationView(view, favorited: isFavorite)
            view.layer.zPosition = isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
        self.routesForStopSortedByArrivals = nil
        self.mapView.removeOverlays(self.mapView.overlays)
        
        dispatch_after(50, dispatch_get_main_queue()) {
            if self.selectedAnnotation == nil {
                self.dismissTableView()
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func buttonPush(sender: AnyObject!) {
        if let annotation = self.mapView.selectedAnnotations.first as? BusStopAnnotation {
            CorvallisBusService.favorites() { favorites in
                var favorites = favorites.filter() { !$0.isNearestStop }
                var addedFavorite = false
                // if this stop is in favorites, remove it
                if favorites.any({ $0.id == annotation.stop.id }) {
                    favorites = favorites.filter() { $0.id != annotation.stop.id }
                } else {
                    // if this stop isn't in favorites, add it
                    favorites.append(annotation.stop)
                    addedFavorite = true
                }
                CorvallisBusService.setFavorites(favorites)
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateFavoritedStateForAnnotation(annotation, favorites: favorites)
                    self.favoriteButton.selected = addedFavorite
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
        var isSelected = false
        if self.selectedAnnotation != nil {
            if let annotationToUpdate = view.annotation as? BusStopAnnotation {
                isSelected = self.selectedAnnotation!.stop.id == annotationToUpdate.stop.id
            }
        }
        
        view.layer.zPosition = favorited || isSelected ? 2 : 1
        if favorited {
            view.image = isSelected ? self.goldOvalHighlightedImage : self.goldOvalImage
        } else {
            view.image = isSelected ? self.greenOvalHighlightedImage : self.greenOvalImage
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
            let arrivalsDescription = friendlyMapArrivals(arrivalsForRoute)
            
            cell.textLabel.text = "\(currentRoute.name): \(arrivalsDescription)"
            cell.detailTextLabel?.text = arrivalsSummary(arrivalsForRoute)
        }
        
        return cell
    }
    
    // MARK - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.routesForStopSortedByArrivals != nil {
            self.mapView.addOverlay(self.routesForStopSortedByArrivals![indexPath.row].polyline)
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.mapView.removeOverlays(self.mapView.overlays)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
