//
//  ArrivalViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/5/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class ArrivalViewController: UIViewController {
    @IBOutlet weak var txtStopName: UILabel!
    @IBOutlet weak var txtArrivalTime: UILabel!
    
    var currentStop: BusStop?
    var arrivalInfo: [StopArrival]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtStopName.text = currentStop?.Name
        
        if currentStop != nil && currentStop?.ID != nil {
            var stop = [currentStop!.ID!]
            CorvallisBusService.arrivals(stop) { result in
                dispatch_async(dispatch_get_main_queue()) {
                    self.arrivalInfo = result
                    self.showArrival()
                }
            }
        }
    }
        
    func showArrival() -> Void {
        if arrivalInfo != nil && arrivalInfo?.count > 0 {
            var arrivals = arrivalInfo![0].arrivals
            txtArrivalTime.text = "\n".join(arrivals.map() { $0.description })
        }
        else {
            txtArrivalTime.text = "No arrivals found!"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func favoriteButtonPressed(sender: UIBarButtonItem) {
        if self.currentStop == nil {
            println("Attempted to add favorite with nil current stop.")
            return
        }
        
        CorvallisBusService.favorites() {
            var favorites = NSMutableArray(array: $0)
            if favorites.containsObject(self.currentStop!) {
                favorites.removeObject(self.currentStop!)
            } else {
                favorites.addObject(self.currentStop!)
            }
            CorvallisBusService.setFavorites(favorites as AnyObject as [BusStop])
        }
        
        let defaults = NSUserDefaults(suiteName: "group.RikkiGibson.CorvallisBus")
        
        let immutableArray = defaults.objectForKey("Favorites") as? NSArray
        var favorites = immutableArray == nil ?
            NSMutableArray() : NSMutableArray(array: immutableArray!)
        
        if currentStop != nil && currentStop!.ID != nil {
            if favorites.containsObject(currentStop!.ID!) {
                favorites.removeObject(currentStop!.ID!)
            } else {
                favorites.addObject(currentStop!.ID!)
            }
        }
        defaults.setObject(favorites, forKey: "Favorites")
        defaults.synchronize()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
