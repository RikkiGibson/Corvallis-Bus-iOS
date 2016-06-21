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

        // Set up the widget list view controller.
        // The contents property should contain an object for each row in the list.
        self.listViewController.contents = []
        self.listViewController.minimumVisibleRowCount = 5
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
        
        NSUserDefaults.groupUserDefaults().favoriteStopIds = [11776, 10308]
        CorvallisBusFavoritesManager.favoriteStops(updateCache: true, fallbackToGrayColor: false, limitResults: true)
                                    .startOnMainThread { self.onUpdateFavorites($0, completionHandler: completionHandler) }
        
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        // Override the left margin so that the list view is flush with the edge.
        var newInsets = defaultMarginInset
        newInsets.left = 0
        return newInsets
    }

    // Can this be deleted?
    var widgetAllowsEditing: Bool {
        // Return true to indicate that the widget supports editing of content and
        // that the list view should be allowed to enter an edit mode.
        return false
    }

    // MARK: - NCWidgetListViewDelegate

    func widgetList(list: NCWidgetListViewController!, viewControllerForRow row: Int) -> NSViewController! {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }

    func widgetList(list: NCWidgetListViewController!, shouldReorderRow row: Int) -> Bool {
        // Return true to allow the item to be reordered in the list by the user.
        return false
    }

    func widgetList(list: NCWidgetListViewController!, shouldRemoveRow row: Int) -> Bool {
        // Return true to allow the item to be removed from the list by the user.
        return true
    }

    func widgetList(list: NCWidgetListViewController!, didRemoveRow row: Int) {
        // The user has removed an item from the list.
        // TODO: delete stop from favorites
    }

}
