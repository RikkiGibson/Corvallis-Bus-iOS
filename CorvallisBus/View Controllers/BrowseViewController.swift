//
//  BrowseViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

final class BrowseViewController: UIViewController, UISearchBarDelegate, BusMapViewControllerDelegate, StopDetailViewControllerDelegate {
    let manager = CorvallisBusManager()
    
    var busMapViewController: BusMapViewController?
    var stopDetailViewController: StopDetailViewController?
    
//    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
//    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var tableViewHeader: UILabel!
    
    @IBOutlet weak var searchBarButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarLeftMargin: NSLayoutConstraint!
    @IBOutlet weak var searchBarRightMargin: NSLayoutConstraint!
    
//    @IBOutlet weak var favoriteButtonBottomMargin: NSLayoutConstraint!
    
    // TODO: can't continue to use this if supporting multiple screen orientations
    private let TABLE_VIEW_HEIGHT: CGFloat = {
        let deviceHeight = UIScreen.mainScreen().bounds.height
        var tableViewHeight = CGFloat(22.0)
        while tableViewHeight / deviceHeight < 0.3 {
            tableViewHeight += 44
        }
        return tableViewHeight
    }()
    
    @IBOutlet weak var locationButton: UIButton!
    
    /// Temporary storage for the stop ID to display once the view controllers are ready to do so.
    private var externalStopID: Int?
    
    private var busAnnotations = [Int : BusStopAnnotation]()
    private var selectedAnnotation: BusStopAnnotation?
    private var timer: NSTimer?
    
    var destinationURL: NSURL?
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "StopDetailEmbed":
            stopDetailViewController = segue.getContentViewController()
            stopDetailViewController!.delegate = self
            break
        case "BusMapEmbed":
            busMapViewController = segue.getContentViewController()
            busMapViewController!.dataSource = manager
            busMapViewController!.delegate = self
            break
        case "BusWebSegue":
            if let destination: BusWebViewController = segue.getContentViewController() {
                destination.initialURL = destinationURL
            }
        default:
            break
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let externalStopID = externalStopID {
            busMapViewController!.selectStopExternally(externalStopID)
            self.externalStopID = nil
        }
    }
    
    func selectStopExternally(stopID: Int) {
        if let busMapViewController = busMapViewController {
            busMapViewController.selectStopExternally(stopID)
        } else {
            // The child view controller isn't ready to
            // receive data, so hold onto the data until then.
            externalStopID = stopID
        }
    }
    
    // MARK: BusMapViewControllerDelegate
    
    func busMapViewController(viewController: BusMapViewController, didSelectStopWithID stopID: Int) {
        if let stopDetailViewController = stopDetailViewController {
            manager.stopDetailsViewModel(stopID).startOnMainThread(stopDetailViewController.updateStopDetails)
        }
    }
    
    func busMapViewControllerDidClearSelection(viewController: BusMapViewController) {
        stopDetailViewController?.updateStopDetails(.Success(StopDetailViewModel.defaultViewModel()))
    }
    
    // MARK: StopDetailViewControllerDelegate
    
    func stopDetailViewController(viewController: StopDetailViewController, didSelectRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .Success(let staticData) = staticData, let route = staticData.routes[routeName] {
                self.busMapViewController?.displayRoute(route)
            }
        }
    }
    
    func stopDetailViewController(viewController: StopDetailViewController, didSelectDetailsForRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .Success(let staticData) = staticData {
                self.destinationURL = staticData.routes[routeName]?.url
                self.performSegueWithIdentifier("BusWebSegue", sender: nil)
            }
        }
    }
    
    func stopDetailViewController(viewController: StopDetailViewController, didSetFavoritedState favorite: Bool, forStopID stopID: Int) {
        busMapViewController?.setFavoriteState(favorite, forStopID: stopID)
        
        let userDefaults = NSUserDefaults.groupUserDefaults()
        if favorite {
            userDefaults.favoriteStopIds = userDefaults.favoriteStopIds + [stopID]
        } else {
            userDefaults.favoriteStopIds = userDefaults.favoriteStopIds.filter{ $0 != stopID }
        }
    }
    
//    private var _selectedRoute: BusRoute?
//    private var selectedRoute: BusRoute? {
//        get {
//            return _selectedRoute
//        }
//        set(newRoute) {
//            if newRoute == _selectedRoute { return }
//            
//            if _selectedRoute != nil {
//                for annotation in self.getNonRouteStopAnnotations(self._selectedRoute!) {
//                    annotation.isDeemphasized = false
//                    if let view = self.mapView.viewForAnnotation(annotation) {
//                        updateStyleForBusAnnotationView(view, annotation: annotation)
//                    }
//                }
//                
//                self.mapView.removeOverlays(self.mapView.overlays)
//                self.mapView.removeAnnotations(_selectedRoute?.arrows ?? [MKAnnotation]())
//            }
//            
//            if newRoute != nil {
//                for annotation in self.getNonRouteStopAnnotations(newRoute!) {
//                    annotation.isDeemphasized = true
//                    if let view = self.mapView.viewForAnnotation(annotation) {
//                        updateStyleForBusAnnotationView(view, annotation: annotation)
//                    }
//                }
//                
//                self.mapView.addOverlay(newRoute!.polyline)
//                self.mapView.addAnnotations(newRoute!.arrows)
//            }
//            _selectedRoute = newRoute
//        }
//    }
    
    private var routeNonStopAnnotations = [String : [BusStopAnnotation]]()
    
    private func getNonRouteStopAnnotations(route: BusRoute) -> [BusStopAnnotation] {
            if routeNonStopAnnotations[route.name] == nil {
                let routeAnnotationSet = route.path.mapUnwrap( { self.busAnnotations[$0] })
                
                routeNonStopAnnotations[route.name] = Array(self.busAnnotations.values.filter() {
                    !routeAnnotationSet.contains($0)
                })
            }
            return routeNonStopAnnotations[route.name]!
    }
    
    private let defaultSpan = MKCoordinateSpanMake(0.01, 0.01)
    
    private let favorite = UIImage(named: "favorite")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        
        self.searchBar.layer.borderWidth = 2.0
        self.searchBar.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.searchBar.layer.cornerRadius = 6
        self.searchBar.clipsToBounds = true
        
        // set the map to a default location when location service is disabled
//        if !CLLocationManager.locationServicesEnabled() {
//            self.mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate,
//                span: MKCoordinateSpanMake(0.04, 0.04)), animated: false)
//            self.mapView.hidden = false
//        }
        
//        let cellNib = UINib(nibName: "BusRouteDetailCell", bundle: NSBundle.mainBundle())
//        self.tableView.registerNib(cellNib, forCellReuseIdentifier: "BusRouteDetailCell")
//        
//        self.tableView.contentInset = UIEdgeInsetsZero
//                
//        self.tableViewHeight.constant = 0
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshMap:",
//            name: UIApplicationDidBecomeActiveNotification, object: nil)
//        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self,
//            selector: "refreshMap:", userInfo: nil, repeats: true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        self.refreshMap(self)
//    }
    
//    func refreshMap(sender: AnyObject) {
//        let authorization = CLLocationManager.authorizationStatus()
//        
//        
//        if #available(iOS 8.0, *) {
//            self.locationButton.hidden =
//                authorization != .AuthorizedWhenInUse &&
//                authorization != .AuthorizedAlways
//        } else {
//            self.locationButton.hidden = authorization != .Authorized
//        }
//        
//        if self.busAnnotations.count == 0 {
//            CorvallisBusAPIClient.stops(initializeStops)
//        } else {
//            self.updateFavoritedStateForAllAnnotationsWithCallback() {
//                if self.initialStop == nil {
//                    self.updateArrivalTimeForSelectedAnnotationView()
//                } else {
//                    self.displayInitialStop()
//                }
//            }
//        }
//    }
    
//    func initializeStops(stops: Failable<[BusStop]>) {
//        // Opening the view while offline can prevent annotations from being added to the map
//        
//        switch stops {
//        case .Success(let stops):
//            self.busAnnotations = stops.toDictionary({ ($0.id, BusStopAnnotation(stop: $0)) })
//            dispatch_async(dispatch_get_main_queue()) {
//                for (_, annotation) in self.busAnnotations {
//                    self.mapView.addAnnotation(annotation)
//                }
//                self.updateFavoritedStateForAllAnnotationsWithCallback(self.displayInitialStop)
//            }
//            break
//        case .Error(let error):
//            self.presentError(error)
//            break
//        }
//        
//    }
    
//    func displayInitialStop() {
//        // initialStop is injected by another view in order to display a particular stop on the map
//        if self.initialStop != nil {
//            
//            if let annotation = self.busAnnotations.tryGet(self.initialStop?.id) {
//                self.mapView.setRegion(MKCoordinateRegion(center: annotation.stop.location.coordinate,
//                    span: self.defaultSpan), animated: true)
//                
//                // prevents wonky appearance if this annotation was already selected, but the map was in a different position
//                self.mapView.deselectAnnotation(annotation, animated: true)
//                self.mapView.selectAnnotation(annotation, animated: true)
//            }
//            
//            self.initializedMapLocation = true
//            self.initialStop = nil
//        }
//    }
    
//    func updateFavoritedStateForAllAnnotationsWithCallback(callback: () -> Void) {
//        // TODO: whyyy not just get the favorites from NSUserDefaults directly?
//        CorvallisBusAPIClient.favorites() { favorites in
//            switch favorites {
//            case .Success(let favorites):
//                let favorites = favorites.filter() { !$0.isNearestStop }
//                dispatch_async(dispatch_get_main_queue()) {
//                    for annotation in self.mapView.annotations {
//                        if let annotation = annotation as? BusStopAnnotation {
//                            self.updateFavoritedStateForAnnotation(annotation, favorites: favorites)
//                        }
//                    }
//                    callback()
//                }
//                break
//            case .Error(let error):
//                self.presentError(error)
//                break
//            }
//            
//            
//        }
//    }
    
    // MARK - Map view delegate
    
//    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
//        if let view = self.mapView.viewForAnnotation(userLocation) {
//            view.canShowCallout = false
//        }
//        if self.mapView.hidden {
//            // If the user is more than roughly 20 miles from Corvallis, don't go to their location
//            if userLocation.location!.distanceFromLocation(CORVALLIS_LOCATION) < 32000 {
//                self.mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate,
//                    span: self.defaultSpan), animated: false)
//            } else {
//                self.mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate,
//                    span: self.defaultSpan), animated:false)
//            }
//            self.mapView.hidden = false
//        }
//    }
    
//    @IBAction func goToUserLocation(sender: AnyObject) {
//        self.searchBar.resignFirstResponder()
//        self.mapView.setCenterCoordinate(self.mapView.userLocation.location!.coordinate, animated: true)
//    }
    
//    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
//        if let polyline = overlay as? MKPolyline {
//            let renderer = MKPolylineRenderer(polyline: polyline)
//            if let selectedIndex = self.tableView.indexPathsForSelectedRows?.first,
//                let currentRoute = self.routesForStopSortedByArrivals?[selectedIndex.row] {
//                    renderer.strokeColor = currentRoute.color
//            }
//            renderer.lineWidth = 5
//            return renderer
//        }
//        return MKOverlayRenderer(overlay: overlay)
//    }
    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//
//        if let annotation = annotation as? BusStopAnnotation {
//            let identifier = "MKAnnotationView"
//            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) ??
//                MKAnnotationView(annotation: annotation, reuseIdentifier: identifier) ?? MKAnnotationView()
//            
//            annotationView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.85)
//            self.updateStyleForBusAnnotationView(annotationView, annotation: annotation)
//            
//            return annotationView
//        } else if let annotation = annotation as? ArrowAnnotation {
//            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("foo") ??
//                MKAnnotationView(annotation: annotation, reuseIdentifier: "foo") ?? MKAnnotationView()
//            annotationView.image = UIImage(named: "ListCurrentLoc")
//            let transform = CGAffineTransformMakeRotation(annotation.angle)
//            annotationView.transform = transform
//            return annotationView
//        }
//        
//        return nil
//    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        if let pin = views.first({ $0 is MKPinAnnotationView }) as? MKPinAnnotationView {
            pin.pinColor = .Purple
            pin.canShowCallout = false
            pin.animatesDrop = true
        }
    }
    
    func presentTableView() {
//        if self.tableViewHeight.constant != self.TABLE_VIEW_HEIGHT {
//            self.tableViewHeight.constant = self.TABLE_VIEW_HEIGHT
//
//            // Declaring this reference prevents the constraint from being
//            // deallocated by ARC when it's removed from the view.
//            let leftMargin = self.searchBarLeftMargin
//            self.searchBar.superview?.removeConstraint(leftMargin)
//            self.searchBarLeftMargin.constant = UIScreen.mainScreen().bounds.width
//            self.searchBarRightMargin.constant = -UIScreen.mainScreen().bounds.width
//            self.searchBar.superview?.addConstraint(leftMargin)
//            self.searchBar.resignFirstResponder()
//        
//            UIView.animateWithDuration(0.2, animations: {
//                self.searchBarButton.alpha = 0.85
//                self.view.layoutIfNeeded()
//            }, completion: { success in
//                if let selectedAnnotation = self.selectedAnnotation
//                    where !self.mapView.annotationsInMapRect(self.mapView.visibleMapRect).contains(selectedAnnotation) {
//                        self.mapView.setCenterCoordinate(selectedAnnotation.coordinate, animated: true)
//                }
//            })
//        }
    }
    
    func dismissTableView() {
//        if self.tableViewHeight.constant != 0 {
//            self.searchBarLeftMargin.constant = 16
//            self.searchBarRightMargin.constant = 16
//            self.tableViewHeight.constant = 0
//            
//            UIView.animateWithDuration(0.2,
//                animations: {
//                    self.searchBarButton.alpha = 0
//                    self.view.layoutIfNeeded()
//                },
//                completion: { success in
//                    if self.searchBarShouldBecomeFirstResponder {
//                        self.searchBar.becomeFirstResponder()
//                        self.searchBarShouldBecomeFirstResponder = false
//                    }
//                    self.tableView.reloadData()
//            })
//        }
    }
    
//    private var routeListNeedsInitialization = false
    /**
        Displays the current arrival time on the annotation's callout, updates the favorited state and
        jumps the annotation to the front.
    */
//    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
//        self.selectedAnnotation = view.annotation as? BusStopAnnotation
//        if self.selectedAnnotation != nil {
//            UIView.animateWithDuration(0.1, animations: {
//                view.transform = CGAffineTransformMakeScale(1.3, 1.3)
//            })
//            
//            self.updateStyleForBusAnnotationView(view,
//                annotation: self.selectedAnnotation!, isSelected: true)
//            self.setFavoriteButtonState(favorited: self.selectedAnnotation!.isFavorite)
//            self.tableViewHeader.text = self.selectedAnnotation!.stop.name
//            self.presentTableView()
//        }
//        self.routeListNeedsInitialization = true
//        self.updateArrivalTime(view)
//    }
    
//    func updateArrivalTimeForSelectedAnnotationView() {
//        if self.selectedAnnotation != nil {
//            if let selectedView = self.mapView.viewForAnnotation(self.selectedAnnotation!) {
//                setFavoriteButtonState(favorited: self.selectedAnnotation!.isFavorite)
//                updateArrivalTime(selectedView)
//            }
//        }
//    }
    
//    func updateArrivalTime(view: MKAnnotationView) {
//        if let annotation = view.annotation as? BusStopAnnotation {
//            CorvallisBusAPIClient.arrivals([annotation.stop.id]) { arrivals in
//                switch arrivals {
//                case .Success(let arrivals):
//                    self.arrivals = arrivals[annotation.stop.id]
//                case .Error(let error):
//                    self.arrivals = nil
//                    self.presentError(error)
//                }
//                self.routesForStopSortedByArrivals = self.arrivals == nil ?
//                    nil : annotation.stop.routesSortedByArrivals(self.arrivals!)
//                dispatch_async(dispatch_get_main_queue(), self.updateTableView)
//            }
//        }
    
        // Clearing the old data after a brief interval prevents
        // miscommunication to the user and make things look snappier.
//        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
//            selector: "clearTableView", userInfo: nil, repeats: false)
//    }
    
//    func clearTableView() {
//        if self.routesForStopSortedByArrivals == nil {
//            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
//        }
//    }

//    func updateTableView() {
//        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
//        if self.routeListNeedsInitialization {
//            let firstIndex = NSIndexPath(forRow: 0, inSection: 0)
//            self.tableView.selectRowAtIndexPath(firstIndex, animated: false, scrollPosition: .None)
//            self.tableView(self.tableView, didSelectRowAtIndexPath: firstIndex)
//            
//            self.routeListNeedsInitialization = false
//        } else if self.routesForStopSortedByArrivals != nil && self.selectedRoute != nil {
//            if let index = (self.routesForStopSortedByArrivals!).indexOf(self.selectedRoute!) {
//                let indexPath = NSIndexPath(forRow: index, inSection: 0)
//                self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
//                self.tableView(self.tableView, didSelectRowAtIndexPath: indexPath)
//            }
//        }
//    }

    /**
        When an annotation is deselected, it should jump to the back if it's not a favorite stop.
    */
//    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
//        self.arrivals = nil
//        self.routesForStopSortedByArrivals = nil
//        
//        if let annotation = self.selectedAnnotation {
//            self.selectedAnnotation = nil
//            UIView.animateWithDuration(0.1, animations: {
//                view.transform = CGAffineTransformIdentity
//            })
//            
//            self.updateStyleForBusAnnotationView(view, annotation: annotation, isSelected: false)
//        } else {
//            print("no annotation was selected during deselection event")
//            view.layer.zPosition = 1
//        }
//        
//        dispatch_after(50, dispatch_get_main_queue()) {
//            if self.selectedAnnotation == nil {
//                self.selectedRoute = nil
//                self.dismissTableView()
//            }
//        }
//    }

//    @IBAction func buttonPush(sender: AnyObject!) {
//        let selectedAnnotation = self.selectedAnnotation!
//        CorvallisBusAPIClient.favorites() { favorites in
//            switch favorites {
//            case .Success(let favorites):
//                var favorites = favorites.filter() { !$0.isNearestStop }
//                var addedFavorite = false
//                // if this stop is in favorites, remove it
//                if favorites.contains(selectedAnnotation.stop) {
//                    favorites = favorites.filter() { $0.id != selectedAnnotation.stop.id }
//                } else {
//                    // if this stop isn't in favorites, add it
//                    favorites.append(selectedAnnotation.stop)
//                    addedFavorite = true
//                }
//                CorvallisBusAPIClient.setFavorites(favorites)
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.updateFavoritedStateForAnnotation(selectedAnnotation, favorites: favorites)
//                    self.setFavoriteButtonState(favorited: addedFavorite)
//                }
//                break
//            case .Error(let error):
//                self.presentError(error)
//                break
//            }
//        }
//    }

    /**
        Updates the state of an annotation to indicate whether it's a favorite.
    */
//    func updateFavoritedStateForAnnotation(annotation: BusStopAnnotation, favorites: [BusStop]) {
//        annotation.isFavorite = favorites.contains(annotation.stop)
//        if let view = self.mapView.viewForAnnotation(annotation) {
//            self.updateStyleForBusAnnotationView(view, annotation: annotation)
//        }
//    }

//    func updateStyleForBusAnnotationView(view: MKAnnotationView, annotation: BusStopAnnotation) {
//        let isSelected = self.selectedAnnotation?.stop.id == annotation.stop.id
//        updateStyleForBusAnnotationView(view, annotation: annotation, isSelected: isSelected)
//    }

    /**
        Updates the appearance of an annotation view to indicate whether it's a favorite.
    */
//    func updateStyleForBusAnnotationView(view: MKAnnotationView, annotation: BusStopAnnotation,
//        isSelected: Bool) {
//            let isFavorite = annotation.isFavorite
//            let isDeemphasized = annotation.isDeemphasized
//            if isSelected {
//                view.layer.zPosition = 5
//                view.image = isFavorite ? self.goldOvalHighlightedImage : self.greenOvalHighlightedImage
//            } else if isDeemphasized {
//                view.layer.zPosition = isFavorite ? 2 : 1
//                view.image = isFavorite ? self.goldOvalDeemphasizedImage : self.greenOvalDeemphasizedImage
//            } else {
//                view.layer.zPosition = isFavorite ? 4 : 3
//                view.image = isFavorite ? self.goldOvalImage : self.greenOvalImage
//            }
//    }

    // MARK - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.routesForStopSortedByArrivals?.count ?? 0
//    }

//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("BusRouteDetailCell") as! BusRouteDetailCell
//        
//        if let currentRoute = self.routesForStopSortedByArrivals?.tryGet(indexPath.row),
//            let arrivalsForRoute = self.arrivals?.filter({ $0.route == currentRoute.name }) {
//                cell.labelRouteName.text = currentRoute.name
//                cell.labelRouteName.backgroundColorActual = currentRoute.color
//                
//                cell.labelEstimate.text = friendlyMapArrivals(arrivalsForRoute)
//                cell.labelSchedule.text = arrivalsSummary(arrivalsForRoute)
//        }
//        return cell
//    }

    // MARK - Table view delegate
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if self.routesForStopSortedByArrivals != nil &&
//            self.routesForStopSortedByArrivals!.count > indexPath.row {
//                self.selectedRoute = self.routesForStopSortedByArrivals?[indexPath.row]
//        }
//    }

//    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
//        self.performSegueWithIdentifier("BusWebSegue",
//            sender: self.routesForStopSortedByArrivals?[indexPath.row])
//    }

    

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.searchBar.resignFirstResponder()
    }

//    func keyboardWillChangeFrame(notification: NSNotification) {
//        if let frame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
//            
//            let keyboardHeight = UIScreen.mainScreen().bounds.height - frame.origin.y
//            self.favoriteButtonBottomMargin.constant = keyboardHeight + 8
//            if keyboardHeight > 0.0 {
//                self.favoriteButtonBottomMargin.constant -= self.tabBarController?.tabBar.frame.height ?? 0
//            }
//        }
//        if let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
//            UIView.animateWithDuration(duration) {
//                self.view.layoutIfNeeded()
//            }
//        }
//    }

//    var searchBarShouldBecomeFirstResponder = false
//    @IBAction func searchButtonPressed(sender: AnyObject) {
//        self.searchBarShouldBecomeFirstResponder = true
//        searchBarShouldBeginEditing(searchBar)
//    }
    
//    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
//        if let annotation = self.selectedAnnotation {
//            self.mapView.deselectAnnotation(annotation, animated: true)
//        }
//        return true
//    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
        return true
    }
    
    func presentNotFoundAlert() {
        self.presentAlert(title: "Not found",
            message: "No Corvallis location with that name was found.")
    }
    
    let zipCodes = ["97330", "97331", "97333", "97339"]
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        self.mapView.removeAnnotations(self.mapView.annotations.filter({$0 is MKPlacemark}))
        searchBarShouldEndEditing(searchBar)
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text
//        request.region = MKCoordinateRegionMakeWithDistance(mapView.centerCoordinate, 32000, 32000)
        
        let search = MKLocalSearch(request: request)
        
        search.startWithCompletionHandler() { response, error in
            if error != nil {
                self.presentNotFoundAlert()
                return
            }
            let typedItems = response?.mapItems
            if let mapItem = typedItems?.first({ self.zipCodes.contains($0.placemark.postalCode!) }) {
                self.searchBar.text = mapItem.name
//                self.mapView.addAnnotation(mapItem.placemark)
//                self.mapView.setRegion(MKCoordinateRegion(center: mapItem.placemark.location!.coordinate,
//                    span: self.defaultSpan), animated: true)
            } else {
                self.presentNotFoundAlert()
            }
        }
    }
    
//    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchText.isEmpty {
//            self.mapView.removeAnnotations(self.mapView.annotations.filter({$0 is MKPlacemark}))
//        }
//    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        
    }
}

extension UIViewController {
    func presentAlert(title title: String, message: String) {
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { action in })
            self.presentViewController(alertController, animated: true) { }
        } else {
            let alertView = UIAlertView(title: title, message: message,
                delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
            alertView.show()
        }
    }
    
    func presentError(message: String) {
        presentAlert(title: "Error", message: message)
    }
}