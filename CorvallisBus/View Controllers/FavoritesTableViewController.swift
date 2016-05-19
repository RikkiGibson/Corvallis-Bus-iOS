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
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "FavoritesTableViewCell", bundle: NSBundle.mainBundle())
        self.tableView.registerNib(cellNib, forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(FavoritesTableViewController.updateFavorites), forControlEvents: .ValueChanged)

        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FavoritesTableViewController.updateFavorites),
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(FavoritesTableViewController.updateFavorites),
            userInfo: nil, repeats: true)
        
        updateFavorites()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        timer?.invalidate()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = NSUserDefaults.groupUserDefaults()
        if !defaults.hasPreviouslyLaunched {
            defaults.hasPreviouslyLaunched = true
            presentTutorial()
        }
    }
    
    func updateFavorites() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        CorvallisBusFavoritesManager.favoriteStops(updateCache: false, fallbackToGrayColor: true, limitResults: false)
            .startOnMainThread(onUpdate)
    }
    
    func onUpdate(result: Failable<[FavoriteStopViewModel], BusError>) {
        favoriteStops = result.toOptional() ?? []
        
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if case .Error(.Message(let message)) = result {
            presentError(message)
        }
    }
    
    // MARK: - Table view data source
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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            // Delete the row from the data source
            favoriteStops.removeAtIndex(indexPath.row)
            
            let userDefaults = NSUserDefaults.groupUserDefaults()
            userDefaults.favoriteStopIds = favoriteStops.filter{ !$0.isNearestStop }.map{ $0.stopId }
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let browseViewController: BrowseViewController = tabBarController!.childViewController() else {
            fatalError("Browse view controller not present as expected")
        }
        browseViewController.selectStopExternally(favoriteStops[indexPath.row].stopId)
        tabBarController!.selectedViewController = browseViewController.navigationController
    }
}
