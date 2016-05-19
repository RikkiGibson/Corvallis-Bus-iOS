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
    let placeholderData = FavoriteStopViewModel(stopName: "Something's not right",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clearColor(), firstRouteName: "", firstRouteArrivals: "Tap to open the app.",
        secondRouteColor: UIColor.clearColor(), secondRouteName: "", secondRouteArrivals: "")
    
    var favoriteStops = [FavoriteStopViewModel]()
    var didCompleteUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TodayTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TodayTableViewCell")
        
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 8)
    }
    
    // MARK: Table view
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Use a placeholder row when favorites is empty (implying failure to load)
        return favoriteStops.isEmpty ? 1 : favoriteStops.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayTableViewCell") as! FavoriteStopTableViewCell
        
        cell.update(favoriteStops.isEmpty
            ? placeholderData
            : favoriteStops[indexPath.row])
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let urlString: String
        if favoriteStops.isEmpty {
            urlString = "CorvallisBus://"
        } else {
            let currentStop = self.favoriteStops[indexPath.row]
            urlString = "CorvallisBus://?\(currentStop.stopId)"
        }
        
        if let url = NSURL(string: urlString) {
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
        favoriteStops = CorvallisBusFavoritesManager.cachedFavoriteStops(fallbackToGrayColor: false)
        tableView.reloadData()
        
        completionHandler(.NewData)
        
        didCompleteUpdate = false
        CorvallisBusFavoritesManager.favoriteStops(updateCache: true, fallbackToGrayColor: false, limitResults: true)
            .startOnMainThread(onUpdate)
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(TodayViewController.clearTableIfUpdatePending), userInfo: nil, repeats: false)
    }
    
    func clearTableIfUpdatePending() {
        if !didCompleteUpdate {
            favoriteStops = []
            NSUserDefaults.groupUserDefaults().cachedFavoriteStops = []
            tableView.reloadData()
        }
    }
    
    func onUpdate(result: Failable<[FavoriteStopViewModel], BusError>) {
        didCompleteUpdate = true
        
        favoriteStops = result.toOptional() ?? []
        self.tableView.reloadData()
        
        if (preferredContentSize != tableView.contentSize) {
            preferredContentSize = tableView.contentSize
        }
    }
}
