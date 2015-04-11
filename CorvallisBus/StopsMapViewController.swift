//
//  StopsMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

final class StopsMapViewController: UIViewController, MKMapViewDelegate,
        UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: UILabel!
    
    @IBOutlet weak var searchBarButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarLeftMargin: NSLayoutConstraint!
    @IBOutlet weak var searchBarRightMargin: NSLayoutConstraint!
    
    @IBOutlet weak var favoriteButtonBottomMargin: NSLayoutConstraint!
    
    // DON'T QUESTION MY METHODS
    private let TABLE_VIEW_HEIGHT: CGFloat = {
        let deviceHeight = UIScreen.mainScreen().bounds.height
        var tableViewHeight = CGFloat(22.0)
        while tableViewHeight / deviceHeight < 0.3 {
            tableViewHeight += 44
        }
        return tableViewHeight
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
    private var timer: NSTimer?
    
    private var _selectedRoute: BusRoute?
    private var selectedRoute: BusRoute? {
        get {
            return _selectedRoute
        }
        set(newRoute) {
            if newRoute == nil {
                self.mapView.removeOverlays(self.mapView.overlays)
            } else if newRoute != _selectedRoute {
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.addOverlay(newRoute!.polyline)
            }
            _selectedRoute = newRoute
        }
    }
    
    private let defaultSpan = MKCoordinateSpanMake(0.01, 0.01)
    private let greenOvalImage = UIImage(named: "greenoval")
    private let greenOvalHighlightedImage = UIImage(named: "greenoval-highlighted")
    private let goldOvalImage = UIImage(named: "goldoval")
    private let goldOvalHighlightedImage = UIImage(named: "goldoval-highlighted")
    
    private let favorite = UIImage(named: "favorite")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        self.searchBar.layer.borderWidth = 2.0
        self.searchBar.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.searchBar.layer.cornerRadius = 6
        self.searchBar.clipsToBounds = true
        
        self.mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate,
            span: MKCoordinateSpanMake(0.04, 0.04)), animated: false)
        
        let cellNib = UINib(nibName: "BusRouteDetailCell", bundle: NSBundle.mainBundle())
        self.tableView.registerNib(cellNib, forCellReuseIdentifier: "BusRouteDetailCell")
        
        self.tableView.contentInset = UIEdgeInsetsZero
                
        self.tableViewHeight.constant = 0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMap:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self,
            selector: "refreshMap:", userInfo: nil, repeats: true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshMap(self)
    }
    
    func refreshMap(sender: AnyObject) {
        let authorization = CLLocationManager.authorizationStatus()
        
        self.locationButton.hidden =
            authorization != .AuthorizedWhenInUse &&
            authorization != .AuthorizedAlways
        
        if self.busAnnotations == nil {
            CorvallisBusService.stops(initializeStops)
        } else {
            self.updateFavoritedStateForAllAnnotationsWithCallback() {
                if self.initialStop == nil {
                    self.updateArrivalTimeForSelectedAnnotationView()
                } else {
                    self.displayInitialStop()
                }
            }
        }
    }
    
    func initializeStops(stops: [BusStop]) {
        // Opening the view while offline can prevent annotations from being added to the map
        self.busAnnotations = stops.map() { BusStopAnnotation(stop: $0) }
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.addAnnotations(self.busAnnotations)
            self.updateFavoritedStateForAllAnnotationsWithCallback() {
                self.displayInitialStop()
            }
        }
    }
    
    func displayInitialStop() {
        // initialStop is injected by another view in order to display a particular stop on the map
        if self.initialStop != nil {
            
            if let annotation = self.busAnnotations?.first(predicate: { $0.stop.id == self.initialStop!.id }) {
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
    
    func updateFavoritedStateForAllAnnotationsWithCallback(callback: () -> Void) {
        CorvallisBusService.favorites() { favorites in
            let favorites = favorites.filter() { !$0.isNearestStop }
            dispatch_async(dispatch_get_main_queue()) {
                for annotation in self.mapView.annotations {
                    if let annotation = annotation as? BusStopAnnotation {
                        self.updateFavoritedStateForAnnotation(annotation, favorites: favorites)
                    }
                }
                callback()
            }
        }
    }
    
    // MARK - Map view delegate
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if let view = self.mapView.viewForAnnotation(userLocation) {
            view.canShowCallout = false
        }
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
        self.searchBar.resignFirstResponder()
        self.mapView.setCenterCoordinate(self.mapView.userLocation.location.coordinate, animated: true)
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            if let selectedIndex = self.tableView.indexPathsForSelectedRows()?.first as? NSIndexPath,
                let currentRoute = self.routesForStopSortedByArrivals?[selectedIndex.row] {
                    renderer.strokeColor = currentRoute.color
            }
            renderer.lineWidth = 5
            return renderer
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if let annotation = annotation as? BusStopAnnotation {
            let identifier = "MKAnnotationView"
            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) ??
                MKAnnotationView(annotation: annotation, reuseIdentifier: identifier) ?? MKAnnotationView()
            
            annotationView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.85)
            self.updateStyleForBusAnnotationView(annotationView, isFavorite: annotation.isFavorite)
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        if let pin = views.first(predicate: { $0 is MKPinAnnotationView }) as? MKPinAnnotationView {
            pin.pinColor = .Purple
            pin.canShowCallout = false
            pin.animatesDrop = true
        }
    }
    
    func presentTableView() {
        if self.tableViewHeight.constant != self.TABLE_VIEW_HEIGHT {
            self.tableViewHeight.constant = self.TABLE_VIEW_HEIGHT
            
            // Declaring this reference prevents the constraint from being
            // deallocated by ARC when it's removed from the view.
            let leftMargin = self.searchBarLeftMargin
            self.searchBar.superview?.removeConstraint(leftMargin)
            self.searchBarLeftMargin.constant = UIScreen.mainScreen().bounds.width
            self.searchBarRightMargin.constant = -UIScreen.mainScreen().bounds.width
            self.searchBar.superview?.addConstraint(leftMargin)
            self.searchBar.resignFirstResponder()
        
            UIView.animateWithDuration(0.2, animations: {
                self.searchBarButton.alpha = 0.85
                self.view.layoutIfNeeded()
            }, completion: { success in
                if let selectedAnnotation = self.selectedAnnotation,
                    let annotations = self.mapView.annotationsInMapRect(self.mapView.visibleMapRect)
                    where !annotations.contains(selectedAnnotation) {
                        self.mapView.setCenterCoordinate(selectedAnnotation.coordinate, animated: true)
                }
            })
        }
    }
    
    func dismissTableView() {
        if self.tableViewHeight.constant != 0 {
            self.searchBarLeftMargin.constant = 16
            self.searchBarRightMargin.constant = 16
            self.tableViewHeight.constant = 0
            
            UIView.animateWithDuration(0.2,
                animations: {
                    self.searchBarButton.alpha = 0
                    self.view.layoutIfNeeded()
                },
                completion: { success in
                    if self.searchBarShouldBecomeFirstResponder {
                        self.searchBar.becomeFirstResponder()
                        self.searchBarShouldBecomeFirstResponder = false
                    }
                    self.tableView.reloadData()
            })
        }
    }
    
    func setFavoriteButtonState(#favorited: Bool) {
        UIView.animateWithDuration(0.2) {
            self.favoriteButton.selected = favorited
            return
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
            UIView.animateWithDuration(0.1, animations: {
                view.transform = CGAffineTransformMakeScale(1.3, 1.3)
            })
            
            self.updateStyleForBusAnnotationView(view, isFavorite: self.selectedAnnotation!.isFavorite, isSelected: true)
            self.setFavoriteButtonState(favorited: self.selectedAnnotation!.isFavorite)
            self.tableViewHeader.text = self.selectedAnnotation!.stop.name
            self.presentTableView()
        }
        self.routeListNeedsInitialization = true
        self.updateArrivalTime(view)
    }
    
    func updateArrivalTimeForSelectedAnnotationView() {
        if self.selectedAnnotation != nil {
            if let selectedView = self.mapView.viewForAnnotation(self.selectedAnnotation!) {
                setFavoriteButtonState(favorited: self.selectedAnnotation!.isFavorite)
                updateArrivalTime(selectedView)
            }
        }
    }
    
    func updateArrivalTime(view: MKAnnotationView) {
        view.layer.zPosition = 2
        
        if let annotation = view.annotation as? BusStopAnnotation {
            CorvallisBusService.arrivals([annotation.stop.id]) { arrivals in
                self.arrivals = arrivals[annotation.stop.id]
                self.routesForStopSortedByArrivals = self.arrivals == nil ?
                    nil : annotation.stop.routesSortedByArrivals(self.arrivals!)
                dispatch_async(dispatch_get_main_queue(), self.updateTableView)
            }
        }
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
            selector: "clearTableView", userInfo: nil, repeats: false)
    }
    
    func clearTableView() {
        if self.routesForStopSortedByArrivals == nil {
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    func updateTableView() {
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        if self.routeListNeedsInitialization {
            let firstIndex = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.selectRowAtIndexPath(firstIndex, animated: false, scrollPosition: .None)
            self.tableView(self.tableView, didSelectRowAtIndexPath: firstIndex)
            
            self.routeListNeedsInitialization = false
        } else if self.routesForStopSortedByArrivals != nil && self.selectedRoute != nil {
            if let index = find(self.routesForStopSortedByArrivals!, self.selectedRoute!) {
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
            }
        }
    }
    
    /**
        When an annotation is deselected, it should jump to the back if it's not a favorite stop.
    */
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        self.arrivals = nil
        self.routesForStopSortedByArrivals = nil
        
        if self.selectedAnnotation != nil {
            UIView.animateWithDuration(0.1, animations: {
                view.transform = CGAffineTransformIdentity
            })
            
            let isFavorite = self.selectedAnnotation!.isFavorite
            self.selectedAnnotation = nil
            self.updateStyleForBusAnnotationView(view, isFavorite: isFavorite, isSelected: false)
            view.layer.zPosition = isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
        
        dispatch_after(50, dispatch_get_main_queue()) {
            if self.selectedAnnotation == nil {
                self.selectedRoute = nil
                self.dismissTableView()
            }
        }
    }
    
    @IBAction func buttonPush(sender: AnyObject!) {
        if let selectedAnnotation = self.selectedAnnotation {
            CorvallisBusService.favorites() { favorites in
                var favorites = favorites.filter() { !$0.isNearestStop }
                var addedFavorite = false
                // if this stop is in favorites, remove it
                if favorites.any(predicate: { $0.id == selectedAnnotation.stop.id }) {
                    favorites = favorites.filter() { $0.id != selectedAnnotation.stop.id }
                } else {
                    // if this stop isn't in favorites, add it
                    favorites.append(selectedAnnotation.stop)
                    addedFavorite = true
                }
                CorvallisBusService.setFavorites(favorites)
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateFavoritedStateForAnnotation(selectedAnnotation, favorites: favorites)
                    self.setFavoriteButtonState(favorited: addedFavorite)
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
            self.updateStyleForBusAnnotationView(view, isFavorite: annotation.isFavorite)
        }
    }
    
    func updateStyleForBusAnnotationView(view: MKAnnotationView, isFavorite: Bool) {
        var isSelected = false
        if let annotationToUpdate = view.annotation as? BusStopAnnotation
            where self.selectedAnnotation != nil {
            isSelected = self.selectedAnnotation!.stop.id == annotationToUpdate.stop.id
        }
        updateStyleForBusAnnotationView(view, isFavorite: isFavorite, isSelected: isSelected)
    }
    
    /**
        Updates the appearance of an annotation view to indicate whether it's a favorite.
    */
    func updateStyleForBusAnnotationView(view: MKAnnotationView, isFavorite: Bool, isSelected: Bool) {
        view.layer.zPosition = isFavorite || isSelected ? 2 : 1
        if isFavorite {
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
        let cell = tableView.dequeueReusableCellWithIdentifier("BusRouteDetailCell") as! BusRouteDetailCell
        
        if let currentRoute = self.routesForStopSortedByArrivals?.tryGet(indexPath.row),
            let arrivalsForRoute = self.arrivals?.filter({ $0.route == currentRoute.name }) {
                cell.labelRouteName.text = currentRoute.name
                cell.labelRouteName.backgroundColorActual = currentRoute.color
                
                cell.labelEstimate.text = friendlyMapArrivals(arrivalsForRoute)
                cell.labelSchedule.text = arrivalsSummary(arrivalsForRoute)
        }
        return cell
    }
    
    // MARK - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.routesForStopSortedByArrivals != nil &&
            self.routesForStopSortedByArrivals!.count > indexPath.row {
                self.selectedRoute = self.routesForStopSortedByArrivals?[indexPath.row]
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("BusWebSegue",
            sender: self.routesForStopSortedByArrivals?[indexPath.row])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? BusWebViewController ??
                segue.destinationViewController.childViewControllers.first as? BusWebViewController,
            let selectedRoute = sender as? BusRoute {
                destination.initialURL = selectedRoute.url
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.searchBar.resignFirstResponder()
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        if let frame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            
            let keyboardHeight = UIScreen.mainScreen().bounds.height - frame.origin.y
            self.favoriteButtonBottomMargin.constant = keyboardHeight + 8
            if keyboardHeight > 0.0 {
                self.favoriteButtonBottomMargin.constant -= self.tabBarController?.tabBar.frame.height ?? 0
            }
        }
        if let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
            UIView.animateWithDuration(duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    var searchBarShouldBecomeFirstResponder = false
    @IBAction func searchButtonPressed(sender: AnyObject) {
        self.searchBarShouldBecomeFirstResponder = true
        searchBarShouldBeginEditing(searchBar)
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        if let annotation = self.selectedAnnotation {
            self.mapView.deselectAnnotation(annotation, animated: true)
        }
        return true
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
    
    func presentNotFoundAlert() {
        if UIAlertControllerWorkaround.deviceDoesSupportUIAlertController() {
            let alertController = UIAlertController(title: "Not found", message: "No Corvallis location with that name was found.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { action in })
            self.presentViewController(alertController, animated: true) { }
        } else {
            let alertView = UIAlertView(title: "Not found", message: "No Corvallis location with that name was found.", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
            alertView.show()
        }
    }
    
    let zipCodes = ["97330", "97331", "97333", "97339"]
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.mapView.removeAnnotations(self.mapView.annotations.filter({$0 is MKPlacemark}))
        searchBarShouldEndEditing(searchBar)
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
        request.region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 32000, 32000)
        
        let search = MKLocalSearch(request: request)
        
        search.startWithCompletionHandler() { response, error in
            if error != nil {
                self.presentNotFoundAlert()
                return
            }
            let typedItems = response.mapItems.mapUnwrap({ $0 as? MKMapItem })
            if let mapItem = typedItems.first(predicate: { contains(self.zipCodes, $0.placemark.postalCode) }) {
                self.searchBar.text = mapItem.name
                self.mapView.addAnnotation(mapItem.placemark)
                self.mapView.setRegion(MKCoordinateRegion(center: mapItem.placemark.location.coordinate,
                    span: self.defaultSpan), animated: true)
            } else {
                self.presentNotFoundAlert()
            }
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.mapView.removeAnnotations(self.mapView.annotations.filter({$0 is MKPlacemark}))
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        
    }
}
