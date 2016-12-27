//
//  BrowseViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/30/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

final class BrowseViewController: UIViewController, BusMapViewControllerDelegate, StopDetailViewControllerDelegate {
    @IBOutlet weak var stopDetailContainer: UIView!
    @IBOutlet weak var constraintStopDetailsPadding: NSLayoutConstraint!
    
    let manager = CorvallisBusManager()
    
    var busMapViewController: BusMapViewController?
    var stopDetailViewController: StopDetailViewController?
    
    /// Temporary storage for the stop ID to display once the view controllers are ready to do so.
    private var externalStopID: Int?
    
    private var timer: Timer?
    
    private var destinationURL: URL?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BrowseViewController.reloadDetails),
            name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self,
            selector: #selector(BrowseViewController.reloadDetails), userInfo: nil, repeats: true)
        
        reloadDetails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let externalStopID = externalStopID {
            busMapViewController!.selectStopExternally(externalStopID)
            self.externalStopID = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        timer?.invalidate()
        userActivity?.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        // Rounds the corners on the table view if it's being shown on an iPad, where
        // it floats on top of the map instead of being flush against the map.
        if constraintStopDetailsPadding.constant == 0 {
            stopDetailContainer.layer.cornerRadius = 0
        } else {
            stopDetailContainer.layer.cornerRadius = 8
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "StopDetailEmbed":
            stopDetailViewController = segue.getContentViewController()
            stopDetailViewController!.delegate = self
        case "BusMapEmbed":
            busMapViewController = segue.getContentViewController()
            busMapViewController!.dataSource = manager
            busMapViewController!.delegate = self
        case "BusWebSegue":
            if let destination: BusWebViewController = segue.getContentViewController() {
                destination.initialURL = destinationURL
            }
        default:
            break
        }
    }
    
    func selectStopExternally(_ stopID: Int) {
        // TODO: change this to a queue
        if let busMapViewController = busMapViewController {
            busMapViewController.selectStopExternally(stopID)
        } else {
            // The child view controller isn't ready to
            // receive data, so hold onto the data until then.
            externalStopID = stopID
        }
    }
    
    // MARK: BusMapViewControllerDelegate
    
    func busMapViewController(_ viewController: BusMapViewController, didSelectStopWithID stopID: Int) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        manager.stopDetailsViewModel(stopID).startOnMainThread(onReloadDetails)
        
        userActivity?.invalidate()
        userActivity = NSUserActivity(activityType: "com.RikkiGibson.CorvallisBus.Browse")
        userActivity!.userInfo = [USER_INFO_STOP_ID_KEY : stopID]
        userActivity!.webpageURL = URL(string: "https://corvallisb.us/#\(stopID)")
        userActivity!.becomeCurrent()
    }
    
    func busMapViewControllerDidClearSelection(_ viewController: BusMapViewController) {
        stopDetailViewController?.updateStopDetails(.success(StopDetailViewModel.empty()))
    }
    
    // MARK: StopDetailViewControllerDelegate
    
    func stopDetailViewController(_ viewController: StopDetailViewController, didSelectRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .success(let staticData) = staticData, let route = staticData.routes[routeName] {
                self.busMapViewController?.displayRoute(route)
            }
        }
    }
    
    func stopDetailViewController(_ viewController: StopDetailViewController, didSelectDetailsForRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .success(let staticData) = staticData,
                let url = staticData.routes[routeName]?.url
            {
                self.presentURL(url)
            }
        }
    }
    
    func stopDetailViewController(_ viewController: StopDetailViewController, didSetFavoritedState favorite: Bool, forStopID stopID: Int) {
        busMapViewController?.setFavoriteState(favorite, forStopID: stopID)
        
        let userDefaults = UserDefaults.groupUserDefaults()
        if favorite {
            userDefaults.favoriteStopIds = userDefaults.favoriteStopIds + [stopID]
        } else {
            userDefaults.favoriteStopIds = userDefaults.favoriteStopIds.filter{ $0 != stopID }
        }
    }
    
    func reloadDetails() {
        if let stopID = busMapViewController?.viewModel.selectedStopID {
            manager.stopDetailsViewModel(stopID).startOnMainThread(onReloadDetails)
        }
    }
    
    func onReloadDetails(_ stopDetails: Failable<StopDetailViewModel, BusError>) {
        stopDetailViewController?.updateStopDetails(stopDetails)
        
        if case .error = stopDetails {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            // on failure, make an another attempt to get the data
            reloadDetails()
        }
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(BrowseViewController.clearSelectionIfDataUnavailable(_:)),
            userInfo: stopDetails.toOptional()?.routeDetails, repeats: false)
    }
    
    /// Clears the selected route from the map and arrival times from the
    /// stop details table if the promise took too long to resolve.
    func clearSelectionIfDataUnavailable(_ timer: Timer) {
        if let details = timer.userInfo as? Promise<[RouteDetailViewModel], BusError>, case .finished = details.state {
            // Just a placeholder because this is the easiest way to match the value
        } else {
            self.busMapViewController?.clearDisplayedRoute()
            self.stopDetailViewController?.clearTableIfDataUnavailable()
        }
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        
    }
}
