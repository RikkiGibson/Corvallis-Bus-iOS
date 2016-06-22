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

    override var nibName: String? {
        return "TodayViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listViewController.showsAddButtonWhenEditing = false
        listViewController.contents = []
        listViewController.minimumVisibleRowCount = NSUserDefaults.groupUserDefaults().todayViewItemCount
    }
    
    func onUpdateFavorites(result: Failable<[FavoriteStopViewModel], BusError>, completionHandler: NCUpdateResult -> Void) {
        switch result {
        case .Success(let models):
            listViewController.contents = models.map({ Box(value: $0) })
            completionHandler(.NewData)
        case .Error(let error):
            // show an error view or something?
            listViewController.contents = []
            completionHandler(.Failed)
            print(error)
            break
        }
    }

    // MARK: - NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        
        let cachedStops = NSUserDefaults.groupUserDefaults()
            .cachedFavoriteStops
            .flatMap({ toFavoriteStopViewModel($0, fallbackToGrayColor: false) })
        listViewController.contents = cachedStops.map({ Box(value: $0) })
        completionHandler(.NewData)
        CorvallisBusFavoritesManager.favoriteStops(updateCache: true, fallbackToGrayColor: false, limitResults: false)
                                    .startOnMainThread { self.onUpdateFavorites($0, completionHandler: completionHandler) }
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: -25, bottom: 0, right: -10)
    }

    // MARK: - NCWidgetListViewDelegate

    func widgetList(list: NCWidgetListViewController!, viewControllerForRow row: Int) -> NSViewController! {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }
}
