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
        CorvallisBusService.routes() { result in
            dispatch_async(dispatch_get_main_queue()) {
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
            cell.textLabel.text = route!.name
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination: AnyObject = segue.destinationViewController
        // iOS 7
        if destination is StopsTableViewController {
            prepareDestination(destination as StopsTableViewController)
        }
        else { // iOS 8
            prepareDestination(destination.childViewControllers.last as StopsTableViewController)
        }
    }
    
    func prepareDestination(destination: StopsTableViewController) {
        let index = self.tableView.indexPathForSelectedRow()
        if routes != nil && index != nil {
            let route = routes![index!.row]
            destination.navigationItem.title = route.name
            destination.stops = route.path
        }
    }
}