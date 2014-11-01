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
    var initializedMapLocation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        
        CorvallisBusService.stops() { stops in
            var annotations = stops.map() { BusStopAnnotation(stop: $0) }
            self.mapView.addAnnotations(annotations);
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        // Update the highlighting of all annotations based on current state of favorites.
        var busStopAnnotations = self.mapView.annotations.mapUnwrap() { $0 as? BusStopAnnotation }
        CorvallisBusService.favorites() { favorites in
            for annotation in busStopAnnotations {
                if let view = self.mapView.viewForAnnotation(annotation) {
                    self.updateSelectedStateForAnnotationView(view, favorites: favorites)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if !self.initializedMapLocation {
            self.mapView.setRegion(MKCoordinateRegion(center: userLocation.coordinate,
                span: MKCoordinateSpanMake(0.05, 0.05)), animated: false)
            self.initializedMapLocation = true
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            // causes default view to be used for user location
            return nil
        }
        
        let identifier = "MKAnnotationView"
        let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) ??
            MKAnnotationView(annotation: annotation, reuseIdentifier: identifier) ?? MKAnnotationView()
    
        if let annotation = annotation as? BusStopAnnotation {
            if annotation.isFavorite {
                annotationView.image = UIImage(named: "goldoval")
                annotationView.layer.zPosition = 2
            }
            else {
                annotationView.image = UIImage(named: "greenoval")
                annotationView.layer.zPosition = 1
            }
            
            annotationView.canShowCallout = true
            
            var button = UIButton.buttonWithType(UIButtonType.ContactAdd) as UIButton
            button.setImage(UIImage(named: "favorite"), forState: UIControlState.Normal)
            button.setImage(UIImage(named: "favorite"), forState: UIControlState.Selected)
            button.selected = annotation.isFavorite
            button.addTarget(self, action: "buttonPush:", forControlEvents: UIControlEvents.TouchUpInside)
            
            annotationView.rightCalloutAccessoryView = button
        }
        
        return annotationView
    }
    
    /**
        Displays the current arrival time on the annotation's callout, updates the favorited state and
        jumps the annotation to the front.
    */
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        view.layer.zPosition = 2
        if let annotation = view.annotation as? BusStopAnnotation {
            CorvallisBusService.arrivals([annotation.stop.id]) { arrivals -> Void in
                if let busArrivals = arrivals[annotation.stop.id] {
                    dispatch_async(dispatch_get_main_queue()) {
                        annotation.willChangeValueForKey("subtitle")
                        annotation.subtitle = busArrivals.first?.description ?? "No arrivals!"
                        annotation.didChangeValueForKey("subtitle")
                    }
                }
            }
            CorvallisBusService.favorites() { self.updateSelectedStateForAnnotationView(view, favorites: $0) }
        }
    }
    
    /**
        When an annotation is deselected, it should jump to the back if it's not a favorite stop.
    */
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        if let annotation = view.annotation as? BusStopAnnotation {
            view.layer.zPosition = annotation.isFavorite ? 2 : 1
        } else {
            view.layer.zPosition = 1
        }
    }
    
    func buttonPush(sender: AnyObject!) {
        if let annotation = self.mapView.selectedAnnotations.first as? BusStopAnnotation {
            let view = self.mapView.viewForAnnotation(annotation)
            CorvallisBusService.favorites() { favorites in
                var favorites = favorites
                // if this stop is in favorites, remove it
                if favorites.any({ $0.id == annotation.stop.id }) {
                    favorites = favorites.filter() { $0.id != annotation.stop.id }
                } else {
                    // if this stop isn't in favorites, add it
                    favorites.append(annotation.stop)
                }
                CorvallisBusService.setFavorites(favorites)
                self.updateSelectedStateForAnnotationView(view, favorites: favorites)
            }
        }
    }
    
    /**
        Updates the image color and button state for an annotation view.
    */
    func updateSelectedStateForAnnotationView(view: MKAnnotationView, favorites: [BusStop]) {
        let button = view.rightCalloutAccessoryView as? UIButton
        let annotation = view.annotation as? BusStopAnnotation
        if button != nil && annotation != nil {
            annotation!.isFavorite = favorites.any() { $0.id == annotation!.stop.id }
            button!.selected = annotation!.isFavorite
            view.image = UIImage(named: annotation!.isFavorite ? "goldoval" : "greenoval")
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
