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
    @IBOutlet weak var mapView: MKMapView!
    let locationManagerDelegate = PromiseLocationManagerDelegate()
    weak var delegate: BusMapViewControllerDelegate?
    weak var dataSource: BusMapViewControllerDataSource?
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], routeArrows: [], routePolyline: nil, selectedStop: nil)
    
    override func viewDidLoad() {
        mapView.delegate = self
        Promise {
            self.locationManagerDelegate.userLocation($0)
        }.startOnMainThread { failable in
            let location = failable.toOptional() ?? CORVALLIS_LOCATION
            self.mapView.setRegion(MKCoordinateRegion(center: location.coordinate, span: DEFAULT_SPAN), animated: false)
        }
        dataSource?.busStopAnnotations().startOnMainThread(populateMap)
        // call our delegate to get viewmodel
        // give map view everything it needs to get started
    }
    
    func populateMap(failable: Failable<[Int : BusStopAnnotation], BusError>) {
        if let annotations = failable.toOptional() {
            for (_, annotation) in annotations {
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    let ANNOTATION_VIEW_IDENTIFIER = "MKAnnotationView"
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? BusStopAnnotation else {
            return nil
        }
        
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(ANNOTATION_VIEW_IDENTIFIER) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_VIEW_IDENTIFIER) ?? MKAnnotationView()
        
        let isSelected = viewModel.selectedStop?.stop.id == annotation.stop.id
        annotationView.updateWithBusStopAnnotation(annotation, isSelected: isSelected)
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation as? BusStopAnnotation else {
            return
        }
        
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
        delegate?.busMapViewControllerDidClearSelection(self)
        
        UIView.animateWithDuration(0.1, animations: {
            view.transform = CGAffineTransformIdentity
        })
        
        view.updateWithBusStopAnnotation(annotation, isSelected: false)
    }
}
