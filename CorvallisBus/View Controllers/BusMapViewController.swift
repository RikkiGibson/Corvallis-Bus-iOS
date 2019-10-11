//
//  BusMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

protocol BusMapViewControllerDelegate : class {
    func busMapViewController(_ viewController: BusMapViewController, didSelectStopWithID stopID: Int)
    func busMapViewControllerDidClearSelection(_ viewController: BusMapViewController)
}

protocol BusMapViewControllerDataSource : class {
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation], BusError>
}

let CORVALLIS_LOCATION = CLLocation(latitude: 44.56802, longitude: -123.27926)
let DEFAULT_SPAN = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
class BusMapViewController : UIViewController, MKMapViewDelegate {
    let locationManagerDelegate = PromiseLocationManagerDelegate()
    
    @IBOutlet weak var mapView: MKMapView!
    
    weak var delegate: BusMapViewControllerDelegate?
    weak var dataSource: BusMapViewControllerDataSource?
    
    /// Temporary storage for the stop ID to display once the view controller is ready to do so.
    private var externalStopID: Int?
    private var reloadTimer: Timer?
    
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], selectedRoute: nil, selectedStopID: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.setRegion(MKCoordinateRegion(center: CORVALLIS_LOCATION.coordinate, span: DEFAULT_SPAN), animated: false)

        locationManagerDelegate.userLocation { maybeLocation in
            // Don't muck with the location if an annotation is selected right now
            guard self.mapView.selectedAnnotations.isEmpty else { return }
            // Only go to the user's location if they're within about 20 miles of Corvallis
            if case .success(let location) = maybeLocation, location.distance(from: CORVALLIS_LOCATION) < 32000 {
                let region = MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN)
                self.mapView.setRegion(region, animated: false)
            }
        }
        dataSource?.busStopAnnotations().startOnMainThread(populateMap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BusMapViewController.reloadAnnotationsIfExpired),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        
        reloadTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(BusMapViewController.reloadAnnotationsIfExpired), userInfo: nil, repeats: true)
        
        let favoriteStopIDs = UserDefaults.groupUserDefaults().favoriteStopIds
        for annotation in viewModel.stops.values {
            annotation.isFavorite = favoriteStopIDs.contains(annotation.stop.id)
            if let view = mapView.view(for: annotation) {
                view.updateWithBusStopAnnotation(annotation,
                                                 isSelected: annotation.stop.id == viewModel.selectedStopID,
                                                 animated: false)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        reloadTimer?.invalidate()
    }
    
    @IBAction func goToUserLocation() {
        locationManagerDelegate.userLocation { maybeLocation in
            if case .success(let location) = maybeLocation {
                let span = self.mapView.region.span
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            } else if case .error(let error) = maybeLocation, let message = error.getMessage() {
                self.presentError(message)
            }
        }
    }
    
    var lastReloadedDate = Date()
    /// The point of this daily reloading stuff is that when stops become active or inactive
    /// over the course of the year (especially when OSU terms start and end) the map will get reloaded.
    /// This is not the cleanest solution (relies on the manager getting new static data every day) but it gets the job done.
    @objc func reloadAnnotationsIfExpired() {
        if !lastReloadedDate.isToday() {
            lastReloadedDate = Date()
            dataSource?.busStopAnnotations().startOnMainThread(populateMap)
        }
    }
    
    func populateMap(_ failable: Failable<[Int : BusStopAnnotation], BusError>) {
        if case .success(let annotations) = failable {
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
    
    func setFavoriteState(_ isFavorite: Bool, forStopID stopID: Int) {
        if let annotation = viewModel.stops[stopID] {
            annotation.isFavorite = isFavorite
            // The annotation view only exists if it's visible
            if let view = mapView.view(for: annotation) {
                let isSelected = viewModel.selectedStopID == stopID
                view.updateWithBusStopAnnotation(annotation, isSelected: isSelected, animated: false)
            }
        }
    }
    
    func selectStopExternally(_ stopID: Int) {
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
        
        for annotation in viewModel.stops.values {
            annotation.isDeemphasized = false
            if let view = mapView.view(for: annotation) {
                view.updateWithBusStopAnnotation(annotation, isSelected: viewModel.selectedStopID == annotation.stop.id, animated: false)
            }
        }
        
        viewModel.selectedRoute = nil
    }
    
    func displayRoute(_ route: BusRoute) {
        guard route.name != viewModel.selectedRoute?.name else {
            return
        }
        
        if let polyline = viewModel.selectedRoute?.polyline {
            mapView.removeOverlay(polyline)
        }
        
        viewModel.selectedRoute = route
        for (stopID, annotation) in viewModel.stops {
            annotation.isDeemphasized = !route.path.contains(stopID)
            if let view = mapView.view(for: annotation) {
                view.updateWithBusStopAnnotation(annotation, isSelected: viewModel.selectedStopID == annotation.stop.id, animated: false)
            }
        }
        mapView.addOverlay(route.polyline)
    }
    
    // MARK: MKMapViewDelegate
    
    let ANNOTATION_VIEW_IDENTIFIER = "MKAnnotationView"
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: ANNOTATION_VIEW_IDENTIFIER) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_VIEW_IDENTIFIER) 
        
        if let annotation = annotation as? BusStopAnnotation {
            let isSelected = viewModel.selectedStopID == annotation.stop.id
            annotationView.updateWithBusStopAnnotation(annotation, isSelected: isSelected, animated: false)
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let view = mapView.view(for: mapView.userLocation) {
            view.isEnabled = false
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? BusStopAnnotation else {
            return
        }
        
        viewModel.selectedStopID = annotation.stop.id
        delegate?.busMapViewController(self, didSelectStopWithID: annotation.stop.id)
        
        view.updateWithBusStopAnnotation(annotation, isSelected: true, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let annotation = view.annotation as? BusStopAnnotation else {
            return
        }
        viewModel.selectedStopID = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.mapView.selectedAnnotations.isEmpty {
                self.clearDisplayedRoute()
                self.delegate?.busMapViewControllerDidClearSelection(self)
            }
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(rotationAngle: CGFloat(annotation.stop.bearing))
        })
        
        view.updateWithBusStopAnnotation(annotation, isSelected: false, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline, let route = viewModel.selectedRoute else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = route.color
        renderer.lineWidth = 5
        return renderer
    }
}
