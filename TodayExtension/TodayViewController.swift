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
    let errorPlaceholder = FavoriteStopViewModel(stopName: "An error occurred",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clearColor(), firstRouteName: "", firstRouteArrivals: "Tap to open the app.",
        secondRouteColor: UIColor.clearColor(), secondRouteName: "", secondRouteArrivals: "")
    
    let emptyPlaceholder = FavoriteStopViewModel(stopName: "No favorites to display",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clearColor(), firstRouteName: "", firstRouteArrivals: "",
        secondRouteColor: UIColor.clearColor(), secondRouteName: "", secondRouteArrivals: "")
    
    let loadingPlaceholder = FavoriteStopViewModel(stopName: "Loading...",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clearColor(), firstRouteName: "", firstRouteArrivals: "",
        secondRouteColor: UIColor.clearColor(), secondRouteName: "", secondRouteArrivals: "")
    
    var favoriteStops: Resource<[FavoriteStopViewModel], BusError> = .Loading
    var didCompleteUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerNib(UINib(nibName: "TodayTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "TodayTableViewCell")

        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 8)
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
        // Use a placeholder row when favorites is empty (either no displayable favorites or failed to load)
        let itemCount = (favoriteStops ?? []).count
        return isWidgetCollapsed() ? 1 : max(1, itemCount)
    }
    
    func viewModel(for row: Int) -> FavoriteStopViewModel {
        if case .Error = favoriteStops {
            return errorPlaceholder
        }
        
        guard case .Success(let viewModels) = favoriteStops else {
            return loadingPlaceholder
        }
        
        if viewModels.isEmpty {
            return emptyPlaceholder
        }
        
        if isWidgetCollapsed() {
            return viewModels.first({ !$0.isNearestStop }) ?? viewModels[row]
        }
        
        return viewModels[row]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TodayTableViewCell") as! FavoriteStopTableViewCell
        
        cell.update(viewModel(for: indexPath.row))
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let urlString: String
        if case .Success(let viewModels) = favoriteStops where !viewModels.isEmpty {
            let selectedStop = viewModels[indexPath.row]
            urlString = "CorvallisBus://?\(selectedStop.stopId)"
        } else {
            urlString = "CorvallisBus://"
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
        favoriteStops = .Success(viewModels)
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = viewModels.count > 1 ? .Expanded : .Compact
        }
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
            favoriteStops = .Loading
            NSUserDefaults.groupUserDefaults().cachedFavoriteStops = []
            tableView.reloadData()
        }
    }
    
    func onUpdate(result: Failable<[FavoriteStopViewModel], BusError>, completionHandler: NCUpdateResult -> Void) {
        didCompleteUpdate = true

        let updateResult: NCUpdateResult
        switch(result) {
        case .Success(let data):
            favoriteStops = .Success(data)
            updateResult = .NewData
            if #available(iOSApplicationExtension 10.0, *) {
                extensionContext?.widgetLargestAvailableDisplayMode = data.count > 1 ? .Expanded : .Compact
            }
        case .Error(let err):
            favoriteStops = .Error(err)
            updateResult = .Failed
            if #available(iOSApplicationExtension 10.0, *) {
                extensionContext?.widgetLargestAvailableDisplayMode = .Compact
            }
        }
        tableView.reloadData()
        
        if (preferredContentSize != tableView.contentSize) {
            preferredContentSize = tableView.contentSize
        }
        
        completionHandler(updateResult)
    }
}
