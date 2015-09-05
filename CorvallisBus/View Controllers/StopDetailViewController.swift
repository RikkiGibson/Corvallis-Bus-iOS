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

    var timer: NSTimer?
    
    weak var delegate: StopDetailViewControllerDelegate?
    
    private var viewModel = StopDetailViewModel.defaultViewModel()
    
    let CELL_IDENTIFIER = "BusRouteDetailCell"
    override func viewDidLoad() {
        let cellNib = UINib(nibName: CELL_IDENTIFIER, bundle: NSBundle.mainBundle())
        tableView.registerNib(cellNib, forCellReuseIdentifier: CELL_IDENTIFIER)
        
        tableView.contentInset = UIEdgeInsetsZero
        updateStopDetails(.Success(StopDetailViewModel.defaultViewModel()))
    }
    
    func updateStopDetails(viewModel: Failable<StopDetailViewModel, BusError>) {
        guard let viewModel = viewModel.toOptional() else {
            return
        }
        // If the previous route details are still pending, don't load them.
        self.viewModel.routeDetails.cancel()
        
        self.viewModel = viewModel
        labelStopName.text = viewModel.stopName
        setFavoriteButtonState(favorited: viewModel.isFavorite)
        
        // stopID being nil indicates no stop is selected
        buttonFavorite.enabled = viewModel.stopID != nil
        
        viewModel.routeDetails.startOnMainThread { failable in
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            if case .Success(let routeDetails) = failable where !routeDetails.isEmpty {
                let firstIndex = NSIndexPath(forRow: 0, inSection: 0)
                self.tableView.selectRowAtIndexPath(firstIndex, animated: true, scrollPosition: .Middle)
                self.tableView(self.tableView, didSelectRowAtIndexPath: firstIndex)
            }
        }
        
        // This causes the route table to clear if the route details are being unresponsive.
        // Can this be factored into the updateRouteDetails method? (it would have to consume a Promise)
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
            selector: "clearTableIfDataUnavailable", userInfo: nil, repeats: false)
    }
    
    func clearTableIfDataUnavailable() {
        switch viewModel.routeDetails.state {
        case .Finished: break
        default: tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
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