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
    func busStopAnnotations() -> Promise<[Int : BusStopAnnotation]>
}

class BusMapViewController : UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    weak var delegate: BusMapViewControllerDelegate?
    var viewModel: BusMapViewModel = BusMapViewModel(stops: [:], routeArrows: [], routePolyline: nil, selectedStop: nil)
    
    override func viewDidLoad() {
        mapView.delegate = self
        
        // call our delegate to get viewmodel
        // give map view everything it needs to get started
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
}
