//
//  BusMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

protocol BusMapViewControllerDelegate : class {
    func busMapViewController(viewController: BusMapViewController, didSelectStopWithID stopID: Int)
    func busMapViewControllerDidClearSelection(viewController: BusMapViewController)
}

protocol BusMapViewControllerDataSource : class {
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation], BusError>
}

let CORVALLIS_LOCATION = CLLocation(latitude: 44.56802, longitude: -123.27926)
let DEFAULT_SPAN = MKCoordinateSpanMake(0.01, 0.01)
class BusMapViewController : UIViewController, MKMapViewDelegate {
    let locationManagerDelegate = PromiseLocationManagerDelegate()
    
    @IBOutlet weak var mapView: MKMapView!
    
    weak var delegate: BusMapViewControllerDelegate?
    weak var dataSource: BusMapViewControllerDataSource?
    
    /// Temporary storage for the stop ID to display once the view controller is ready to do so.
    private var externalStopID: Int?
    private var reloadTimer: NSTimer?
    
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], selectedRoute: nil, selectedStopID: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate, span: DEFAULT_SPAN), animated: false)

        locationManagerDelegate.userLocation { maybeLocation in
            // Don't muck with the location if an annotation is selected right now
            guard self.mapView.selectedAnnotations.isEmpty else { return }
            let location = maybeLocation.toOptional() ?? CORVALLIS_LOCATION
            let region = MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN)
            self.mapView.setRegion(region, animated: false)
        }
        dataSource?.busStopAnnotations().startOnMainThread(populateMap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadAnnotationsIfExpired",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        reloadTimer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "reloadAnnotationsIfExpired", userInfo: nil, repeats: true)
        
        let favoriteStopIDs = NSUserDefaults.groupUserDefaults().favoriteStopIds
        for annotation in viewModel.stops.values {
            annotation.isFavorite = favoriteStopIDs.contains(annotation.stop.id)
            if let view = mapView.viewForAnnotation(annotation) {
                view.updateWithBusStopAnnotation(annotation, isSelected: annotation.stop.id == viewModel.selectedStopID)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        reloadTimer?.invalidate()
    }
    
    @IBAction func goToUserLocation() {
        locationManagerDelegate.userLocation { maybeLocation in
            if case .Success(let location) = maybeLocation {
                let span = self.mapView.region.span
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            } else if case .Error(let error) = maybeLocation, let message = error.getMessage() {
                self.presentError(message)
            }
        }
    }
    
    var lastReloadedDate = NSDate()
    /// The point of this daily reloading stuff is that when stops become active or inactive
    /// over the course of the year (especially when OSU terms start and end) the map will get reloaded.
    /// This is not the cleanest solution (relies on the manager getting new static data every day) but it gets the job done.
    func reloadAnnotationsIfExpired() {
        if !lastReloadedDate.isToday() {
            lastReloadedDate = NSDate()
            dataSource?.busStopAnnotations().startOnMainThread(populateMap)
        }
    }
    
    func populateMap(failable: Failable<[Int : BusStopAnnotation], BusError>) {
        if case .Success(let annotations) = failable {
            mapView.removeAnnotations(mapView.annotations.filter{ $0 is BusStopAnnotation })
            viewModel.stops = annotations
            for annotation in annotations.values {
                mapView.addAnnotation(annotation)
            }
            if let externalStopID = externalStopID {
                self.externalStopID = nil
                selectStopExternally(externalStopID)
            }
        } else {
            // The request failed. Try again.
            dataSource?.busStopAnnotations().startOnMainThread(populateMap)
        }
    }
    
    func setFavoriteState(isFavorite: Bool, forStopID stopID: Int) {
        if let annotation = viewModel.stops[stopID] {
            annotation.isFavorite = isFavorite
            // The annotation view only exists if it's visible
            if let view = mapView.viewForAnnotation(annotation) {
                let isSelected = viewModel.selectedStopID == stopID
                view.updateWithBusStopAnnotation(annotation, isSelected: isSelected)
            }
        }
    }
    
    func selectStopExternally(stopID: Int) {
        if let annotation = viewModel.stops[stopID] {
            // select the annotation that currently exists
            let region = MKCoordinateRegion(center: annotation.stop.location.coordinate, span: DEFAULT_SPAN)
            mapView.setRegion(region, animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        } else {
            // select this stop once data is populated
            externalStopID = stopID
        }
    }
    
    func clearDisplayedRoute() {
        
        if let polyline = viewModel.selectedRoute?.polyline {
            mapView.removeOverlay(polyline)
        }
        if let arrows = viewModel.selectedRoute?.arrows {
            mapView.removeAnnotations(arrows)
        }
        
        for annotation in viewModel.stops.values {
            annotation.isDeemphasized = false
            if let view = mapView.viewForAnnotation(annotation) {
                view.updateWithBusStopAnnotation(annotation, isSelected: viewModel.selectedStopID == annotation.stop.id)
            }
        }
        
        viewModel.selectedRoute = nil
    }
    
    func displayRoute(route: BusRoute) {
        guard route.name != viewModel.selectedRoute?.name else {
            return
        }
        
        if let polyline = viewModel.selectedRoute?.polyline {
            mapView.removeOverlay(polyline)
        }
        if let arrows = viewModel.selectedRoute?.arrows {
            mapView.removeAnnotations(arrows)
        }
        
        viewModel.selectedRoute = route
        for (stopID, annotation) in viewModel.stops {
            annotation.isDeemphasized = !route.path.contains(stopID)
            if let view = mapView.viewForAnnotation(annotation) {
                view.updateWithBusStopAnnotation(annotation, isSelected: viewModel.selectedStopID == annotation.stop.id)
            }
        }
        mapView.addOverlay(route.polyline)
        mapView.addAnnotations(route.arrows)
    }
    
    // MARK: MKMapViewDelegate
    
    let ANNOTATION_VIEW_IDENTIFIER = "MKAnnotationView"
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(ANNOTATION_VIEW_IDENTIFIER) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_VIEW_IDENTIFIER) ?? MKAnnotationView()
        
        if let annotation = annotation as? BusStopAnnotation {
            let isSelected = viewModel.selectedStopID == annotation.stop.id
            annotationView.updateWithBusStopAnnotation(annotation, isSelected: isSelected)
        } else if let annotation = annotation as? ArrowAnnotation {
            annotationView.updateWithArrowAnnotation(annotation)
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        if let view = mapView.viewForAnnotation(mapView.userLocation) {
            view.enabled = false
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation as? BusStopAnnotation else {
            return
        }
        
        viewModel.selectedStopID = annotation.stop.id
        delegate?.busMapViewController(self, didSelectStopWithID: annotation.stop.id)
        
        UIView.animateWithDuration(0.1, animations: {
            view.transform = CGAffineTransformMakeScale(1.3, 1.3)
        })
        
        view.updateWithBusStopAnnotation(annotation, isSelected: true)
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation as? BusStopAnnotation else {
            return
        }
        viewModel.selectedStopID = nil
        
        dispatch_after(50, dispatch_get_main_queue()) {
            if self.mapView.selectedAnnotations.isEmpty {
                self.clearDisplayedRoute()
                self.delegate?.busMapViewControllerDidClearSelection(self)
            }
        }
        
        UIView.animateWithDuration(0.1, animations: {
            view.transform = CGAffineTransformIdentity
        })
        
        view.updateWithBusStopAnnotation(annotation, isSelected: false)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline, route = viewModel.selectedRoute else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = route.color
        renderer.lineWidth = 5
        return renderer
    }
}
