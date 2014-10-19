//
//  StopsTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/24/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class RoutesTableViewController : UITableViewController {
    var routes: [BusRoute]?
    
    override func viewDidLoad() {
        CorvallisBusService.routes() { (result) -> Void in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.routes = result
                self.tableView.reloadData()
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let value = routes {
            return value.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("TableViewCell") as UITableViewCell

        var route = self.routes?[indexPath.row]
        if route != nil {
            cell.textLabel!.text = route!.description
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as UINavigationController
        var actualDestination = destination.childViewControllers.last as StopsTableViewController
        if let routes = routes {
            if let index = self.tableView.indexPathForSelectedRow() {
                let route = routes[index.row]
                actualDestination.navigationItem.title = route.description
                actualDestination.stops = route.path
            }
        }
    }
}