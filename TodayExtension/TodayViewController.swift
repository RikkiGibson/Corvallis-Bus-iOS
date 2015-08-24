//
//  TodayViewController.swift
//  CorvallisBusTodayExtension
//
//  Created by Rikki Gibson on 10/15/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import NotificationCenter

final class TodayViewController: UITableViewController, NCWidgetProviding {
    var favoriteStops = [FavoriteStopViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TodayTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TodayTableViewCell")
        
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 8)
        
    }
    
    // MARK: Table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteStops.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayTableViewCell") as! FavoriteStopTableViewCell
        
        cell.update(favoriteStops[indexPath.row])
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let currentStop = self.favoriteStops[indexPath.row]
        if let url = NSURL(string: "CorvallisBus://?\(currentStop.stopId)") {
            self.extensionContext?.openURL(url) { success in }
        }
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top,
            left: defaultMarginInsets.left - 50,
            bottom: defaultMarginInsets.bottom,
            right: defaultMarginInsets.right)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        let cache = NSUserDefaults.groupUserDefaults().cachedFavoriteStops
        favoriteStops = cache.mapUnwrap{ toFavoriteStopViewModel($0, fallbackToGrayColor: false) }
        tableView.reloadData()
        
        completionHandler(.NewData)
        
        let userDefaults = NSUserDefaults.groupUserDefaults()
        CorvallisBusFavoritesManager.favoriteStops(userDefaults.favoriteStopIds)
            .startOnMainThread(onUpdate)
    }
    
    func onUpdate(result: Failable<[[String : AnyObject]]>) {
        let userDefaults = NSUserDefaults.groupUserDefaults()
        let shouldShowNearestStop = userDefaults.shouldShowNearestStop
        let limit = userDefaults.todayViewItemCount
        
        favoriteStops = result.map{ (json: [[String : AnyObject]]) -> [FavoriteStopViewModel] in
            let viewModels = json.mapUnwrap{ toFavoriteStopViewModel($0, fallbackToGrayColor: false) }
            return shouldShowNearestStop ? viewModels.limit(limit) : viewModels.filter{ !$0.isNearestStop }.limit(limit)
        }.toOptional() ?? [FavoriteStopViewModel]()
        self.tableView.reloadData()
        
        if (preferredContentSize != tableView.contentSize) {
            preferredContentSize = tableView.contentSize
        }
        
        userDefaults.cachedFavoriteStops = result.toOptional() ?? [[String : AnyObject]]()
    }
}
