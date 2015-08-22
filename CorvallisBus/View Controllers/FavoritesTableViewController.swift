//
//  FavoritesTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/17/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

final class FavoritesTableViewController: UITableViewController {
    var favoriteStops = [FavoriteStopViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "FavoritesTableViewCell", bundle: NSBundle.mainBundle())
        self.tableView.registerNib(cellNib, forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "updateFavorites", forControlEvents: .ValueChanged)
        
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "updateFavorites",
            userInfo: nil, repeats: true)

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateFavorites",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        updateFavorites()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateFavorites() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        CorvallisBusClient.getFavoriteStops(limit: nil, fallbackToGrayColor: true, callback: onUpdate)
    }
    
    func onUpdate(result: Failable<[[String : AnyObject]]>) {
        favoriteStops = result.map{ maybeJSON in
            maybeJSON.mapUnwrap{ toFavoriteStopViewModel($0, fallbackToGrayColor: false) }
        }.toOptional() ?? [FavoriteStopViewModel]()
        
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let error = result.toError() {
            self.presentError(error)
        }
        
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favoriteStops.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesTableViewCell", forIndexPath: indexPath) as! FavoriteStopTableViewCell
        
        cell.update(favoriteStops[indexPath.row])
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let selectedStop = self.favoriteStops[indexPath.row]
        return !selectedStop.isNearestStop
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            favoriteStops.removeAtIndex(indexPath.row)
            
            let userDefaults = NSUserDefaults.groupUserDefaults()
            userDefaults.favoriteStopIds = favoriteStops.filter{ !$0.isNearestStop }.map{ $0.stopId }
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) { // TODO fix
//        if let map = self.tabBarController?.viewControllers?[1].childViewControllers.first as? StopsMapViewController {
//            map.initialStop = self.favorites[indexPath.row]
//            self.tabBarController?.selectedIndex = 1
//        }
    }
}
