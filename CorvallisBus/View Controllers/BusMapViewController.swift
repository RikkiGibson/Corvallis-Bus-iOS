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
    
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], routeArrows: [], routePolyline: nil, selectedStopID: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        locationManagerDelegate.userLocation { maybeLocation in
            // Don't muck with the location if an annotation is selected right now
            guard self.mapView.selectedAnnotations.isEmpty else { return }
            let location = maybeLocation.toOptional() ?? CORVALLIS_LOCATION
            let region = MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN)
            self.mapView.setRegion(region, animated: false)
        }
        
        dataSource?.busStopAnnotations().startOnMainThread(populateMap)
    }
    
    func populateMap(failable: Failable<[Int : BusStopAnnotation], BusError>) {
        if case .Success(let annotations) = failable {
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
    
    // MARK: MKMapViewDelegate
    
    let ANNOTATION_VIEW_IDENTIFIER = "MKAnnotationView"
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? BusStopAnnotation else {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(ANNOTATION_VIEW_IDENTIFIER) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_VIEW_IDENTIFIER) ?? MKAnnotationView()
        
        let isSelected = viewModel.selectedStopID == annotation.stop.id
        annotationView.updateWithBusStopAnnotation(annotation, isSelected: isSelected)
        
        return annotationView
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
        delegate?.busMapViewControllerDidClearSelection(self)
        
        UIView.animateWithDuration(0.1, animations: {
            view.transform = CGAffineTransformIdentity
        })
        
        view.updateWithBusStopAnnotation(annotation, isSelected: false)
    }
}
