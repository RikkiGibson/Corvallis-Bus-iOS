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
    var arrivals: [Int : [BusArrival]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "FavoritesTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "updateList:", forControlEvents: .ValueChanged)
        self.refreshControl?.beginRefreshing()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateList(self)
    }
    
    func updateList(sender: AnyObject) {
        CorvallisBusService.favorites() {
            self.favorites = $0
            self.updateArrivals()
            dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
        }
    }
    
    func updateArrivals() {
        if self.favorites != nil {
            CorvallisBusService.arrivals(self.favorites!.map() { $0.id }) {
                self.arrivals = $0
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if self.favorites != nil {
            return self.favorites!.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesTableViewCell", forIndexPath: indexPath) as FavoriteStopTableViewCell
        
        // Configure the cell...
        if self.favorites != nil {
            let stop = favorites![indexPath.row]
            cell.labelRouteName.text = stop.name
            if self.arrivals != nil {
                if let busArrivals = arrivals![stop.id] {
                    cell.labelArrivals.text = busArrivals.any() ?
                        "\n".join(busArrivals.map() { $0.description }) : "No arrivals!"
                }
            }
            
            let metersToMiles = 0.000621371
            if stop.distanceFromUser != nil {
                let distanceInMiles = String(format: "%1.1f", stop.distanceFromUser! * metersToMiles)
                cell.labelDistance.text = distanceInMiles + " miles"
            }
        }
        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            if self.favorites != nil {
                self.favorites!.removeAtIndex(indexPath.row)
                CorvallisBusService.setFavorites(self.favorites!)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let map = self.tabBarController?.viewControllers?[1].childViewControllers.first as? StopsMapViewController {
            map.initialStop = favorites?[indexPath.row]
            self.tabBarController?.selectedIndex = 1
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */
}
