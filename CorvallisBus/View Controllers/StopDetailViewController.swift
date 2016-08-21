//
//  StopDetailTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

protocol StopDetailViewControllerDelegate : class {
    func stopDetailViewController(viewController: StopDetailViewController, didSetFavoritedState favorite: Bool, forStopID stopID: Int)
    func stopDetailViewController(viewController: StopDetailViewController, didSelectRouteNamed routeName: String)
    func stopDetailViewController(viewController: StopDetailViewController, didSelectDetailsForRouteNamed routeName: String)
}

final class StopDetailViewController : UITableViewController {
    @IBOutlet weak var labelStopName: UILabel!
    @IBOutlet weak var buttonFavorite: UIButton!
    
    weak var delegate: StopDetailViewControllerDelegate?
    
    private var viewModel = StopDetailViewModel.empty()
    
    let CELL_IDENTIFIER = "BusRouteDetailCell"
    override func viewDidLoad() {
        let cellNib = UINib(nibName: CELL_IDENTIFIER, bundle: NSBundle.mainBundle())
        tableView.registerNib(cellNib, forCellReuseIdentifier: CELL_IDENTIFIER)
        
        tableView.contentInset = UIEdgeInsetsZero
        updateStopDetails(.Success(StopDetailViewModel.empty()))
        
        // Rounds the corners on the table view if it's being shown on an iPad, where
        // it floats on top of the map instead of being flush against the map.
        let traitCollection = UIScreen.mainScreen().traitCollection
        if traitCollection.verticalSizeClass == .Regular && traitCollection.horizontalSizeClass == .Regular {
            tableView.layer.cornerRadius = 8
        } else {
            tableView.layer.cornerRadius = 0
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StopDetailViewController.onOrientationChanged), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func onOrientationChanged() {
        // Simple workaround to get the label to show text at the right width
        // when the screen orientation goes from landscape to portrait.
        labelStopName.text = viewModel.stopName
    }
    
    func updateStopDetails(viewModel: Failable<StopDetailViewModel, BusError>) {
        guard let viewModel = viewModel.toOptional() else {
            return
        }
        // If the previous route details are still pending, don't load them.
        self.viewModel.routeDetails.cancel()
        
        // Indicates whether this is just a reload of the same stop or a different stop was selected.
        let didSelectDifferentStop = self.viewModel.stopID != viewModel.stopID
        let selectedRouteName = self.viewModel.selectedRouteName
        
        self.viewModel = viewModel
        labelStopName.text = viewModel.stopName
        setFavoriteButtonState(favorited: viewModel.isFavorite)
        
        // stopID being nil indicates no stop is selected
        buttonFavorite.enabled = viewModel.stopID != nil
        
        viewModel.routeDetails.startOnMainThread { failable in
            // stackoverflow claims this may fix a crash
            self.tableView.beginUpdates()
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            self.tableView.endUpdates()
            
            if case .Success(let routeDetails) = failable where !routeDetails.isEmpty {
                let indexToSelect = didSelectDifferentStop
                    ? NSIndexPath(forRow: 0, inSection: 0)
                    : NSIndexPath(forRow: routeDetails.indexOf{ $0.routeName == selectedRouteName } ?? 0, inSection: 0)
                self.tableView.selectRowAtIndexPath(indexToSelect, animated: true, scrollPosition: .None)
                self.tableView(self.tableView, didSelectRowAtIndexPath: indexToSelect)
            }
        }
    }
    
    func clearTableIfDataUnavailable() {
        switch viewModel.routeDetails.state {
        case .Finished: break
        default:
            tableView.beginUpdates()
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
    }
    
    // MARK: Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if case .Finished(.Success(let routeDetails)) = viewModel.routeDetails.state {
            return routeDetails.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as! BusRouteDetailCell
        
        if case .Finished(.Success(let routeDetails)) = viewModel.routeDetails.state {
            cell.update(routeDetails[indexPath.row])
        }
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard case .Finished(.Success(let routeDetails)) = viewModel.routeDetails.state else {
            return
        }
        let routeName = routeDetails[indexPath.row].routeName
        viewModel.selectedRouteName = routeName
        delegate?.stopDetailViewController(self, didSelectRouteNamed: routeName)
    }
    
    @IBAction func toggleFavorite() {
        guard let stopID = viewModel.stopID else {
            return
        }
        viewModel.isFavorite = !viewModel.isFavorite
        setFavoriteButtonState(favorited: viewModel.isFavorite)
        delegate?.stopDetailViewController(self, didSetFavoritedState: viewModel.isFavorite, forStopID: stopID)
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        guard case .Finished(.Success(let routeDetails)) = viewModel.routeDetails.state else {
            return
        }
        let routeName = routeDetails[indexPath.row].routeName
        delegate?.stopDetailViewController(self, didSelectDetailsForRouteNamed: routeName)
    }
    
    func setFavoriteButtonState(favorited favorited: Bool) {
        UIView.animateWithDuration(0.2) {
            self.buttonFavorite.selected = favorited
        }
    }
}
