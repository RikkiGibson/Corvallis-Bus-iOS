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
        self.tableView.registerNib(UINib(nibName: "TodayTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TodayTableViewCell")
        
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
        return self.favoriteStops?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayTableViewCell") as FavoriteStopTableViewCell!
        
        if let currentStop = self.favoriteStops?[indexPath.row] {
            cell.labelRouteName.text = currentStop.name
            
            if let busArrivals = self.arrivals?[currentStop.id] {
                cell.labelArrivals.text = friendlyArrivals(busArrivals)
            }
            cell.locationImage.hidden = !currentStop.isNearestStop
            
            cell.labelDistance.text = currentStop.friendlyDistance
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let currentStop = self.favoriteStops?[indexPath.row] {
            if let url = NSURL(string: "CorvallisBus://?\(currentStop.id)") {
                self.extensionContext?.openURL(url) { success in }
            }
        }
    }
    
    func updateFavoriteStops() {
        CorvallisBusService.favorites() { result in
            let todayItemCount = CorvallisBusService.todayViewItemCount
            self.favoriteStops = result.count < todayItemCount ? result : Array(result[0..<todayItemCount])
            self.updateArrivals()
            dispatch_async(dispatch_get_main_queue()) {
                self.preferredContentSize = self.tableView.contentSize
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: Data access
    func updateArrivals() {
        if self.favoriteStops != nil {
            var favIds = self.favoriteStops!.map() { $0.id }
            CorvallisBusService.arrivals(favIds) {
                self.arrivals = $0
                dispatch_async(dispatch_get_main_queue()) {
                    self.preferredContentSize = self.tableView.contentSize
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top,
            left: defaultMarginInsets.left - 3,
            bottom: defaultMarginInsets.bottom,
            right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        updateFavoriteStops()
        completionHandler(NCUpdateResult.NewData)
    }
}
