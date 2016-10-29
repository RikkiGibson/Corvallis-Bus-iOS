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
    
    var favoriteStops: [FavoriteStopViewModel] = []
    var didCompleteUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TodayTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TodayTableViewCell")

        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 8)
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .Expanded
        }
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        reloadCachedFavorites()
        if activeDisplayMode == .Compact {
            self.preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, self.tableView.contentSize.height))
        } else {
            self.preferredContentSize = CGSize(width: maxSize.width, height: self.tableView.contentSize.height)
        }
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
    
    func isWidgetCollapsed() -> Bool {
        if #available(iOSApplicationExtension 10.0, *) {
            return (extensionContext?.widgetActiveDisplayMode == NCWidgetDisplayMode.Compact) ?? false
        } else {
            return false
        }
    }
    func reloadCachedFavorites() {
        let viewModels = CorvallisBusFavoritesManager.cachedFavoriteStopsForWidget()
        favoriteStops = filterFavoriteStops(viewModels)
        tableView.reloadData()
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        reloadCachedFavorites()
        
        didCompleteUpdate = false
        CorvallisBusFavoritesManager.favoriteStopsForWidget()
            .startOnMainThread({ self.onUpdate($0, completionHandler: completionHandler) })
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(TodayViewController.clearTableIfUpdatePending), userInfo: nil, repeats: false)
    }
    
    func clearTableIfUpdatePending() {
        if !didCompleteUpdate {
            favoriteStops = []
            NSUserDefaults.groupUserDefaults().cachedFavoriteStops = []
            tableView.reloadData()
        }
    }
    
    func filterFavoriteStops(favorites: [FavoriteStopViewModel]) -> [FavoriteStopViewModel] {
        let defaults = NSUserDefaults.groupUserDefaults()
        let favorites = defaults.shouldShowNearestStop ? favorites : favorites.filter({ !$0.isNearestStop })
        if isWidgetCollapsed() {
            let maybeFavorite = favorites.first({ !$0.isNearestStop }) ?? favorites.first
            let singleOrNoFavorite = maybeFavorite.map({ [$0] }) ?? []
            return singleOrNoFavorite
        } else {
            return favorites.limit(defaults.todayViewItemCount)
        }
    }
    
    func onUpdate(result: Failable<[FavoriteStopViewModel], BusError>, completionHandler: NCUpdateResult -> Void) {
        didCompleteUpdate = true

        let updateResult: NCUpdateResult
        switch(result) {
        case .Success(let data):
            favoriteStops = filterFavoriteStops(data)
            updateResult = .NewData
        case .Error:
            favoriteStops = []
            updateResult = .Failed
        }
        tableView.reloadData()
        
        if (preferredContentSize != tableView.contentSize) {
            preferredContentSize = tableView.contentSize
        }
        
        completionHandler(updateResult)
    }
}
