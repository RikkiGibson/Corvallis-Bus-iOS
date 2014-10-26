//
//  TodayViewController.swift
//  CorvallisBusTodayExtension
//
//  Created by Rikki Gibson on 10/15/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UITableViewController, NCWidgetProviding {
    var favoriteStops: [BusStop]?
    var arrivals: [Int : [BusArrival]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "FavoriteStopTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "FavoriteStopTableViewCell")
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let favoriteStops = favoriteStops {
            return favoriteStops.count
        }
        return 0
    }
    
//    func updatePreferredContentSize() {
//        preferredContentSize = CGSizeMake(CGFloat(0), CGFloat(tableView(tableView, numberOfRowsInSection: 0)) * 2 * CGFloat(tableView.rowHeight) + tableView.sectionFooterHeight)
//        println(preferredContentSize)
//    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FavoriteStopTableViewCell") as TodayTableViewCell!
        
        if let favoriteStops = self.favoriteStops {
            let currentStop = favoriteStops[indexPath.row]
            cell.labelRouteName.text = currentStop.name
            
            if self.arrivals != nil {
                let busArrivals = self.arrivals![currentStop.id]
                if busArrivals != nil {
                    cell.labelArrivals.text = "\n".join(busArrivals!.map() { $0.description })
                }
            }
            
            if currentStop.distanceFromUser != nil {
                let distanceInMiles = String(format: "%1.1f", currentStop.distanceFromUser! * 0.000621371)
                cell.labelDistance.text = distanceInMiles + " miles"
            }
        }
        
        return cell
    }
    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animateAlongsideTransition({ context in
//            self.tableView.frame = CGRectMake(0, 0, size.width, size.height)
//            }, completion: nil)
//    }
    
    // MARK: Data access
    func updateArrivals() {
        if let favoriteStops = self.favoriteStops {
            var favIds = favoriteStops.map() { $0.id }
            CorvallisBusService.arrivals(favIds) {
                self.arrivals = $0
                dispatch_async(dispatch_get_main_queue()) { self.tableView.reloadData() }
            }
        }
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        CorvallisBusService.favorites() { result in
            self.favoriteStops = result
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
                self.updateArrivals()
            }
        }
        
        completionHandler(NCUpdateResult.NewData)
    }
}
