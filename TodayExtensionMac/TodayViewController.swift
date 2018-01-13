//
//  TodayViewController.swift
//  TodayExtensionMac
//
//  Created by Rikki Gibson on 6/12/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate {
    @IBOutlet var listViewController: NCWidgetListViewController!
    
    // MARK: - NSViewController

    override var nibName: NSNib.Name? {
        return NSNib.Name(rawValue: "TodayViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listViewController.showsAddButtonWhenEditing = false
        listViewController.contents = []
        listViewController.minimumVisibleRowCount = UserDefaults.groupUserDefaults().todayViewItemCount
    }
    
    func onUpdateFavorites(_ result: Failable<[FavoriteStopViewModel], BusError>, completionHandler: (NCUpdateResult) -> Void) {
        switch result {
        case .success(let models):
            listViewController.contents = models.map({ Box(value: $0) })
            completionHandler(.newData)
        case .error(let error):
            // show an error view or something?
            listViewController.contents = []
            completionHandler(.failed)
            print(error)
            break
        }
    }

    // MARK: - NCWidgetProviding

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        
        let cachedStops = UserDefaults.groupUserDefaults()
            .cachedFavoriteStops
            .flatMap({ toFavoriteStopViewModel($0, fallbackToGrayColor: false) })
        listViewController.contents = cachedStops.map({ Box(value: $0) })
        completionHandler(.newData)
        CorvallisBusFavoritesManager.favoriteStopsForWidget()
                                    .startOnMainThread { self.onUpdateFavorites($0, completionHandler: completionHandler) }
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        return NSEdgeInsetsZero
    }

    // MARK: - NCWidgetListViewDelegate

    func widgetList(_ list: NCWidgetListViewController, viewControllerForRow row: Int) -> NSViewController {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        let viewController = ListRowViewController()
        
        let appearanceName = parent?.view.effectiveAppearance.name
        viewController.hasDarkAppearance = appearanceName == NSAppearance.Name.vibrantDark
        
        return viewController
    }
}
