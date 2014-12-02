//
//  FavoritesTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/17/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

class FavoritesTableViewController: UITableViewController {
    var favorites: [BusStop]?
    var arrivals: [Int : String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "FavoritesTableViewCell", bundle: NSBundle.mainBundle())
        self.tableView.registerNib(cellNib, forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "updateFavorites:", forControlEvents: .ValueChanged)
        
        // This observer causes updateFavorites to be called without further intervention
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateFavorites:",
            name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "updateFavorites:",
            userInfo: nil, repeats: true)

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    // Called when switching to this tab, not when reopening the app or
    // bringing focus back after dismissing Notification Center, for instance.
    // Since DidBecomeActiveNotification fires on launch, we avoid
    // redundant network requests with the finishedLoading flag.
    private var finishedLoading = false
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.finishedLoading {
            self.updateFavorites(self)
        } else {
            self.finishedLoading = true
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateFavorites(sender: AnyObject) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        CorvallisBusService.favorites() {
            self.favorites = $0
            dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
            self.updateArrivals()
        }
    }
    
    func updateArrivals() {
        if self.favorites != nil {
            CorvallisBusService.arrivals(self.favorites!.map() { $0.id }) {
                self.arrivals = $0.map() { (key, value) in (key, friendlyArrivals(value)) }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    // Causes routes to get deserialized. This takes several seconds on old phones.
                    CorvallisBusService.routes() { routes in }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
        } else { // this shouldn't happen
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favorites?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesTableViewCell", forIndexPath: indexPath) as FavoriteStopTableViewCell
        
        if let currentStop = self.favorites?[indexPath.row] {
            cell.labelRouteName.text = currentStop.name
            
            if let busArrivals = self.arrivals?[currentStop.id] {
                cell.labelArrivals.text = busArrivals
            }
            
            // Only the nearest stop should display the location icon
            cell.locationImage.hidden = !currentStop.isNearestStop
            
            cell.labelDistance.text = currentStop.friendlyDistance
        }
        
        return cell
    }

    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let currentStop = self.favorites?[indexPath.row] {
            return !currentStop.isNearestStop
        }
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            if self.favorites != nil {
                self.favorites!.removeAtIndex(indexPath.row)
                CorvallisBusService.setFavorites(self.favorites!.filter() { !$0.isNearestStop })
                
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let map = self.tabBarController?.viewControllers?[1].childViewControllers.first as? StopsMapViewController {
            map.initialStop = self.favorites?[indexPath.row]
            self.tabBarController?.selectedIndex = 1
        }
    }
}
