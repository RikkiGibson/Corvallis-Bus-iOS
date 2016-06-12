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

class BusMapViewController: NSViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    weak var dataSource: BusMapViewControllerDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Do view setup here.
        
        dataSource?.busStopAnnotations().startOnMainThread(onStopsLoaded)
    }
    
    func onStopsLoaded(result: Failable<[Int : BusStopAnnotation], BusError>) {
        switch result {
        case .Success(let stops):
            mapView.addAnnotations(Array(stops.values))
        case .Error(let error):
            // TODO: show something
            print(error)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? BusStopAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(String(String)) ??
                MKAnnotationView(annotation: annotation, reuseIdentifier: String(String))
            annotationView.updateWithBusStopAnnotation(annotation, isSelected: false)
            return annotationView
        }
        
        return mapView.dequeueReusableAnnotationViewWithIdentifier("MKAnnotationView") ??
               MKAnnotationView(annotation: annotation, reuseIdentifier: "MKAnnotationView")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? BusStopAnnotation {
            view.updateWithBusStopAnnotation(annotation, isSelected: true)
            
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view!.setAffineTransform(CGAffineTransformMakeScale(1.3, 1.3))
//            NSAnimationContext.endGrouping()
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        
        if let annotation = view.annotation as? BusStopAnnotation {
            view.updateWithBusStopAnnotation(annotation, isSelected: false)
            
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.1
//            view.layer!.setAffineTransform(CGAffineTransformMakeScale(1.0, 1.0))
//            NSAnimationContext.endGrouping()
        }
    }
}
