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
    let manager = CorvallisBusManager()
    
    var busMapViewController: BusMapViewController?
    var stopDetailViewController: StopDetailViewController?
    
    /// Temporary storage for the stop ID to display once the view controllers are ready to do so.
    private var externalStopID: Int?
    
    private var timer: NSTimer?
    
    private var destinationURL: NSURL?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowseViewController.reloadDetails),
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self,
            selector: #selector(BrowseViewController.reloadDetails), userInfo: nil, repeats: true)
        
        reloadDetails()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let externalStopID = externalStopID {
            busMapViewController!.selectStopExternally(externalStopID)
            self.externalStopID = nil
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        timer?.invalidate()
        userActivity?.invalidate()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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
    
    func selectStopExternally(stopID: Int) {
        if let busMapViewController = busMapViewController {
            busMapViewController.selectStopExternally(stopID)
        } else {
            // The child view controller isn't ready to
            // receive data, so hold onto the data until then.
            externalStopID = stopID
        }
    }
    
    // MARK: BusMapViewControllerDelegate
    
    func busMapViewController(viewController: BusMapViewController, didSelectStopWithID stopID: Int) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        manager.stopDetailsViewModel(stopID).startOnMainThread(onReloadDetails)
        
        userActivity?.invalidate()
        userActivity = NSUserActivity(activityType: "com.RikkiGibson.CorvallisBus.Browse")
        userActivity!.userInfo = [USER_INFO_STOP_ID_KEY : stopID]
        userActivity!.webpageURL = NSURL(string: "https://corvallisb.us/#\(stopID)")
        userActivity!.becomeCurrent()
    }
    
    func busMapViewControllerDidClearSelection(viewController: BusMapViewController) {
        stopDetailViewController?.updateStopDetails(.Success(StopDetailViewModel.defaultViewModel()))
    }
    
    // MARK: StopDetailViewControllerDelegate
    
    func stopDetailViewController(viewController: StopDetailViewController, didSelectRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .Success(let staticData) = staticData, let route = staticData.routes[routeName] {
                self.busMapViewController?.displayRoute(route)
            }
        }
    }
    
    func stopDetailViewController(viewController: StopDetailViewController, didSelectDetailsForRouteNamed routeName: String) {
        manager.staticData().startOnMainThread { staticData in
            if case .Success(let staticData) = staticData {
                self.destinationURL = staticData.routes[routeName]?.url
                self.performSegueWithIdentifier("BusWebSegue", sender: nil)
            }
        }
    }
    
    func stopDetailViewController(viewController: StopDetailViewController, didSetFavoritedState favorite: Bool, forStopID stopID: Int) {
        busMapViewController?.setFavoriteState(favorite, forStopID: stopID)
        
        let userDefaults = NSUserDefaults.groupUserDefaults()
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
    
    func onReloadDetails(stopDetails: Failable<StopDetailViewModel, BusError>) {
        stopDetailViewController?.updateStopDetails(stopDetails)
        
        if case .Error(let error) = stopDetails {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let message = error.getMessage() {
                presentError(message)
            }
            // on failure, make an another attempt to get the data
            reloadDetails()
        } else if case .Success(let stopDetails) = stopDetails {
            stopDetails.routeDetails.startOnMainThread{ routeDetails in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if case .Error(let error) = routeDetails, let message = error.getMessage() {
                    self.presentError(message)
                }
            }
        }
        
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BrowseViewController.clearSelectionIfDataUnavailable(_:)),
            userInfo: stopDetails.toOptional()?.routeDetails, repeats: false)
    }
    
    func clearSelectionIfDataUnavailable(timer: NSTimer) {
        if let details = timer.userInfo as? Promise<[RouteDetailViewModel], BusError>, case .Finished = details.state {
            // Just a placeholder because this is the easiest way to match the value
        } else {
            self.busMapViewController?.clearDisplayedRoute()
            self.stopDetailViewController?.clearTableIfDataUnavailable()
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        
    }
}
