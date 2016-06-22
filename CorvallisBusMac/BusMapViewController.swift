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
            if case .Success(let location) = maybeLocation where location.distanceFromLocation(CORVALLIS_LOCATION) < 32000 {
                let region = MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN)
                self.mapView.setRegion(region, animated: false)
            }
        }
        
        dataSource?.busStopAnnotations().startOnMainThread(onStopsLoaded)
    }
    
    // MARK: StopSelectionDelegate
    
    func onStopSelected(stopID: Int) {
        if let annotation = viewModel.stops[stopID] {
            mapView.setCenterCoordinate(annotation.stop.location.coordinate, animated: true)
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    func onStopsLoaded(result: Failable<[Int: BusStopAnnotation], BusError>) {
        switch result {
        case .Success(let stops):
            viewModel.stops = stops
            mapView.addAnnotations(Array(stops.values))
            if let externalStopID = AppDelegate.dequeueSelectedStopID() {
                onStopSelected(externalStopID)
            }
            AppDelegate.stopSelectionDelegate = self
        case .Error(let error):
            // TODO: show something
            print(error)
        }
    }
    
    func onButtonClick(button: NSButton) {
        guard let selectedStop = selectedStop else {
            return
        }
        let defaults = NSUserDefaults.groupUserDefaults()
        var favorites = defaults.favoriteStopIds
        if let index = favorites.indexOf(selectedStop.stop.id) {
            selectedStop.isFavorite = false
            favorites.removeAtIndex(index)
        } else {
            favorites.append(selectedStop.stop.id)
            selectedStop.isFavorite = true
        }
        button.highlighted = selectedStop.isFavorite
        if let view = mapView.viewForAnnotation(selectedStop) {
            view.updateWithBusStopAnnotation(selectedStop, isSelected: true)
        }
        defaults.favoriteStopIds = favorites
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BusStopAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(String(BusStopAnnotation)) ??
                                 MKAnnotationView(annotation: annotation, reuseIdentifier: String(BusStopAnnotation))
            annotationView.updateWithBusStopAnnotation(annotation, isSelected: false)
            
            let button = NSButton()
            button.image = NSImage(named: "favorite")
            button.alternateImage = NSImage(named: "favorite")
            button.bezelStyle = NSBezelStyle.RegularSquareBezelStyle
            button.target = self
            button.action = #selector(BusMapViewController.onButtonClick)
            
            annotationView.rightCalloutAccessoryView = button
            annotationView.canShowCallout = true
            return annotationView
        }
        
        if annotation is MKUserLocation {
            return nil
        }
        
        return mapView.dequeueReusableAnnotationViewWithIdentifier(String(MKAnnotationView)) ??
               MKAnnotationView(annotation: annotation, reuseIdentifier: String(MKAnnotationView))
    }
    
    // can this variable be avoided?
    var selectedStop: BusStopAnnotation?
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? BusStopAnnotation {
            view.updateWithBusStopAnnotation(annotation, isSelected: true)
            selectedStop = annotation
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view!.setAffineTransform(CGAffineTransformMakeScale(1.3, 1.3))
//            NSAnimationContext.endGrouping()
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        
        if let annotation = view.annotation as? BusStopAnnotation {
            view.updateWithBusStopAnnotation(annotation, isSelected: false)
            selectedStop = nil
            
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view.layer!.setAffineTransform(CGAffineTransformMakeScale(1.0, 1.0))
//            NSAnimationContext.endGrouping()
        }
    }
}
