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
    
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], routeArrows: [], routePolyline: nil, selectedStopID: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "selectStopFromBackground",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        mapView.delegate = self
        
        Promise {
            self.locationManagerDelegate.userLocation($0)
        }.startOnMainThread { failable in
            guard self.viewModel.selectedStopID == nil else { return }
            let location = failable.toOptional() ?? CORVALLIS_LOCATION
            self.mapView.setRegion(MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN), animated: false)
        }
        
        dataSource?.busStopAnnotations().startOnMainThread(populateMap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Repeated selections of this stop allow external controllers to modify the selected stop
        // and see results, as well as allowing listeners to our selection to update.
        selectStop()
    }
    
    func populateMap(failable: Failable<[Int : BusStopAnnotation], BusError>) {
        if let annotations = failable.toOptional() {
            viewModel.stops = annotations
            for annotation in annotations.values {
                mapView.addAnnotation(annotation)
            }
        }
        selectStop()
    }
    
    func setFavoriteState(isFavorite: Bool, forStopID stopID: Int) {
        if let annotation = viewModel.stops[stopID], let view = mapView.viewForAnnotation(annotation) {
            annotation.isFavorite = isFavorite
            let isSelected = viewModel.selectedStopID == stopID
            view.updateWithBusStopAnnotation(annotation, isSelected: isSelected)
        }
    }
    
    func selectStopFromBackground() {
        dispatch_async(dispatch_get_main_queue(), selectStop)
    }
    
    func selectStop() {
        guard let selectedStopID = viewModel.selectedStopID, annotation = viewModel.stops[selectedStopID] else {
            return
        }
        let region = MKCoordinateRegion(center: annotation.stop.location.coordinate, span: DEFAULT_SPAN)
        self.mapView.setRegion(region, animated: true)
        self.mapView.deselectAnnotation(annotation, animated: true)
        self.mapView.selectAnnotation(annotation, animated: true)
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
