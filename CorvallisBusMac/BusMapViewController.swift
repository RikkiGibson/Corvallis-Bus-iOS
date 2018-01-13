//
//  BusMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 6/12/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa
import MapKit

protocol BusMapViewControllerDataSource : class {
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation], BusError>
}

let CORVALLIS_LOCATION = CLLocation(latitude: 44.56802, longitude: -123.27926)
let DEFAULT_SPAN = MKCoordinateSpanMake(0.01, 0.01)
class BusMapViewController: NSViewController, MKMapViewDelegate, StopSelectionDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    weak var dataSource: BusMapViewControllerDataSource?
    let locationManagerDelegate = PromiseLocationManagerDelegate()
    var viewModel = BusMapViewModel(stops: [:], selectedRoute: nil, selectedStopID: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
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
        
        dataSource?.busStopAnnotations().startOnMainThread(onStopsLoaded)
    }
    
    // MARK: StopSelectionDelegate
    
    func onStopSelected(stopID: Int) {
        if let annotation = viewModel.stops[stopID] {
            mapView.setCenter(annotation.stop.location.coordinate, animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    func onStopsLoaded(result: Failable<[Int: BusStopAnnotation], BusError>) {
        switch result {
        case .success(let stops):
            viewModel.stops = stops
            mapView.addAnnotations(Array(stops.values))
            if let externalStopID = AppDelegate.dequeueSelectedStopID() {
                onStopSelected(stopID: externalStopID)
            }
            AppDelegate.stopSelectionDelegate = self
        case .error(let error):
            // TODO: show something
            print(error)
        }
    }
    
    @objc func onButtonClick(_ button: NSButton) {
        guard let selectedStop = selectedStop else {
            return
        }
        let defaults = UserDefaults.groupUserDefaults()
        var favorites = defaults.favoriteStopIds
        if let index = favorites.index(of: selectedStop.stop.id) {
            selectedStop.isFavorite = false
            favorites.remove(at: index)
        } else {
            favorites.append(selectedStop.stop.id)
            selectedStop.isFavorite = true
        }
        button.isHighlighted = selectedStop.isFavorite
        if let view = mapView.view(for: selectedStop) {
            view.update(with: selectedStop, isSelected: true)
        }
        defaults.favoriteStopIds = favorites
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BusStopAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: String(describing: BusStopAnnotation.self)) ??
                                 MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: BusStopAnnotation.self))
            annotationView.update(with: annotation, isSelected: false)
            
            let button = NSButton()
            button.image = NSImage(named: NSImage.Name(rawValue: "favorite"))
            button.alternateImage = NSImage(named: NSImage.Name(rawValue: "favorite"))
            button.bezelStyle = .regularSquare
            button.target = self
            button.action = #selector(BusMapViewController.onButtonClick)
            
            annotationView.rightCalloutAccessoryView = button
            annotationView.canShowCallout = true
            return annotationView
        }
        
        if annotation is MKUserLocation {
            return nil
        }
        
        return mapView.dequeueReusableAnnotationView(withIdentifier: String(describing: MKAnnotationView.self)) ??
               MKAnnotationView(annotation: annotation, reuseIdentifier: String(describing: MKAnnotationView.self))
    }
    
    // can this variable be avoided?
    var selectedStop: BusStopAnnotation?
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? BusStopAnnotation {
            view.update(with: annotation, isSelected: true)
            selectedStop = annotation
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view!.setAffineTransform(CGAffineTransformMakeScale(1.3, 1.3))
//            NSAnimationContext.endGrouping()
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
        if let annotation = view.annotation as? BusStopAnnotation {
            view.update(with: annotation, isSelected: false)
            selectedStop = nil
            
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view.layer!.setAffineTransform(CGAffineTransformMakeScale(1.0, 1.0))
//            NSAnimationContext.endGrouping()
        }
    }
}
