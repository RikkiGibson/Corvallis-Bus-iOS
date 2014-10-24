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
    @IBOutlet weak var btnFavorite: UIBarButtonItem!
    
    var currentStop: BusStop?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtStopName.text = currentStop?.name
    }
    
    override func viewWillAppear(animated: Bool) {
        updateArrivals()
        updateFavoriteButtonText()
    }
    
    func updateArrivals() -> Void {
        if currentStop != nil {
            CorvallisBusService.arrivals([currentStop!.id]) { stopArrivals in
                dispatch_async(dispatch_get_main_queue()) { self.showArrivals(stopArrivals) }
            }
        }
    }
    
    func updateFavoriteButtonText() -> Void {
        self.btnFavorite.title = ""
        
        if self.currentStop != nil {
            CorvallisBusService.favorites() { favorites in
                dispatch_async(dispatch_get_main_queue()) {
                    self.btnFavorite.title = favorites.any() { $0.id == self.currentStop!.id }
                        ? "Unfavorite" : "Favorite"
                }
            }
        }
    }
        
    func showArrivals(stopArrivals: [Int : [BusArrival]]) -> Void {
        var busArrivals: [BusArrival]?
        if self.currentStop != nil {
            busArrivals = stopArrivals[self.currentStop!.id]
        }
        if busArrivals != nil {
            txtArrivalTime.text = "\n".join(busArrivals!.map() { $0.description })
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
        
        CorvallisBusService.favorites() { favorites in
            var favorites = favorites
            if favorites.any({ favorite in favorite.id == self.currentStop!.id }) {
                favorites = favorites.filter() { favorite in favorite.id != self.currentStop!.id }
                sender.title = "Favorite"
            } else {
                favorites.append(self.currentStop!)
                sender.title = "Unfavorite"
            }
            CorvallisBusService.setFavorites(favorites)
        }
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
