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
        firstRouteColor: UIColor.clear, firstRouteName: "", firstRouteArrivals: "Tap to open the app.",
        secondRouteColor: UIColor.clear, secondRouteName: "", secondRouteArrivals: "")
    
    let emptyPlaceholder = FavoriteStopViewModel(stopName: "No favorites to display",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clear, firstRouteName: "", firstRouteArrivals: "Tap to open the app.",
        secondRouteColor: UIColor.clear, secondRouteName: "", secondRouteArrivals: "")
    
    let loadingPlaceholder = FavoriteStopViewModel(stopName: "Loading...",
        stopId: 0, distanceFromUser: "", isNearestStop: false,
        firstRouteColor: UIColor.clear, firstRouteName: "", firstRouteArrivals: "",
        secondRouteColor: UIColor.clear, secondRouteName: "", secondRouteArrivals: "")
    
    var favoriteStops: Resource<[FavoriteStopViewModel], BusError> = .loading
    var didCompleteUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "TodayTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "TodayTableViewCell")

        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 66, bottom: 0, right: 8)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        reloadCachedFavorites()
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: maxSize.width, height: min(maxSize.height, self.tableView.contentSize.height))
        } else {
            self.preferredContentSize = CGSize(width: maxSize.width, height: self.tableView.contentSize.height)
        }
    }
    
    // MARK: Table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Use a placeholder row when favorites is empty (either no displayable favorites or failed to load)
        let itemCount = (favoriteStops ?? []).count
        return isWidgetCollapsed() ? 1 : max(1, itemCount)
    }
    
    func viewModel(for row: Int) -> FavoriteStopViewModel {
        if case .error = favoriteStops {
            return errorPlaceholder
        }
        
        guard case .success(let viewModels) = favoriteStops else {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayTableViewCell") as! FavoriteStopTableViewCell
        
        cell.update(viewModel(for: indexPath.row))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let urlString: String
        if case .success(let viewModels) = favoriteStops, !viewModels.isEmpty {
            let selectedStop = viewModels[indexPath.row]
            urlString = "CorvallisBus://?\(selectedStop.stopId)"
        } else {
            urlString = "CorvallisBus://"
        }
        
        if let url = URL(string: urlString) {
            self.extensionContext?.open(url) { success in }
        }
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: defaultMarginInsets.top,
            left: defaultMarginInsets.left - 50,
            bottom: defaultMarginInsets.bottom,
            right: defaultMarginInsets.right)
    }
    
    func isWidgetCollapsed() -> Bool {
        if #available(iOSApplicationExtension 10.0, *) {
            return extensionContext?.widgetActiveDisplayMode == NCWidgetDisplayMode.compact
        } else {
            return false
        }
    }
    
    func reloadCachedFavorites() {
        let viewModels = CorvallisBusFavoritesManager.cachedFavoriteStopsForWidget()
        favoriteStops = .success(viewModels)
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = viewModels.count > 1 ? .expanded : .compact
        }
        tableView.reloadData()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        reloadCachedFavorites()
        
        didCompleteUpdate = false
        CorvallisBusFavoritesManager.favoriteStopsForWidget()
            .startOnMainThread({ self.onUpdate($0, completionHandler: completionHandler) })
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TodayViewController.clearTableIfUpdatePending), userInfo: nil, repeats: false)
    }
    
    func clearTableIfUpdatePending() {
        if !didCompleteUpdate {
            favoriteStops = .loading
            UserDefaults.groupUserDefaults().cachedFavoriteStops = []
            tableView.reloadData()
        }
    }
    
    func onUpdate(_ result: Failable<[FavoriteStopViewModel], BusError>, completionHandler: (NCUpdateResult) -> Void) {
        didCompleteUpdate = true

        let updateResult: NCUpdateResult
        switch(result) {
        case .success(let data):
            favoriteStops = .success(data)
            updateResult = .newData
            if #available(iOSApplicationExtension 10.0, *) {
                extensionContext?.widgetLargestAvailableDisplayMode = data.count > 1 ? .expanded : .compact
            }
        case .error(let err):
            favoriteStops = .error(err)
            updateResult = .failed
            if #available(iOSApplicationExtension 10.0, *) {
                extensionContext?.widgetLargestAvailableDisplayMode = .compact
            }
        }
        tableView.reloadData()
        
        if (preferredContentSize != tableView.contentSize) {
            preferredContentSize = tableView.contentSize
        }
        
        completionHandler(updateResult)
    }
}
