//
//  StopsMapViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

class StopsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var stops: [BusStop]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        CorvallisBusService.stops() { stops in
            self.stops = stops
            var annotations = stops.map() { stop in
                BusStopAnnotation(title: stop.name, id: stop.id, coordinate: stop.location.coordinate)
            }
            self.mapView.addAnnotations(annotations);
        }
        // Do any additional setup after loading the view.
    }
    
    var didInitializeMapLocation = false
    override func viewWillAppear(animated: Bool) {
        self.didInitializeMapLocation = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if !self.didInitializeMapLocation {
            mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpanMake(0.1, 0.1)), animated: false)
            self.didInitializeMapLocation = true
            mapView.userTrackingMode = .Follow
        }
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        // Put the user location annotation at the front
        var userLocationView = views.first() { $0.annotation?.title == "Current Location" } as? MKAnnotationView
        if userLocationView != nil {
            userLocationView!.superview?.bringSubviewToFront(userLocationView!)
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let identifier = "MKAnnotationView"
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: identifier) ?? MKAnnotationView()
        
        if annotationView.annotation?.title == "Current Location" {
            return nil
        }
        annotationView.image = UIImage(named: "greenoval")
        //annotationView.enabled = true
        annotationView.canShowCallout = true
        //annotationView.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as UIView
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if let annotation = view.annotation as? BusStopAnnotation {
            CorvallisBusService.arrivals([annotation.id]) { arrivals -> Void in
                if let busArrivals = arrivals[annotation.id] {
                    annotation.subtitle = "\n".join(busArrivals.map() { $0.description })
                    mapView.selectAnnotation(annotation, animated: false)
                }
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
