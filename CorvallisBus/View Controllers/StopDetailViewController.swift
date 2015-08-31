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
}

final class StopDetailViewController : UITableViewController {
    @IBOutlet weak var labelStopName: UILabel!
    @IBOutlet weak var buttonFavorite: UIButton!

    var timer: NSTimer?
    
    weak var delegate: StopDetailViewControllerDelegate?
    
    private var viewModel = StopDetailViewModel(stopName: "", stopID: 0, routeDetails: [], isFavorite: false)
    
    let CELL_IDENTIFIER = "BusRouteDetailCell"
    override func viewDidLoad() {
        let cellNib = UINib(nibName: CELL_IDENTIFIER, bundle: NSBundle.mainBundle())
        tableView.registerNib(cellNib, forCellReuseIdentifier: CELL_IDENTIFIER)
        
        tableView.contentInset = UIEdgeInsetsZero
    }
    
    func updateStopDetails(viewModel: Failable<StopDetailViewModel, BusError>) {
        guard let viewModel = viewModel.toOptional() else {
            return
        }
        self.viewModel = viewModel
        labelStopName.text = viewModel.stopName
        setFavoriteButtonState(favorited: viewModel.isFavorite)
        
        // This causes the route table to clear if the route details are being unresponsive.
        // Can this be factored into the updateRouteDetails method? (it would have to consume a Promise)
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
            selector: "refreshTableIfEmpty", userInfo: nil, repeats: false)
    }
    
    func updateRouteDetails(viewModel: Failable<[RouteDetailViewModel], BusError>) {
        guard case .Success(let viewModel) = viewModel else {
            return
        }
        self.viewModel.routeDetails = viewModel
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    func refreshTableIfEmpty() {
        if viewModel.routeDetails.isEmpty {
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    // MARK: Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.routeDetails.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as! BusRouteDetailCell
        
        cell.update(viewModel.routeDetails[indexPath.row])
        
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let routeName = viewModel.routeDetails[indexPath.row].routeName
        delegate?.stopDetailViewController(self, didSelectRouteNamed: routeName)
    }
    
    @IBAction func toggleFavorite() {
        viewModel.isFavorite = !viewModel.isFavorite
        setFavoriteButtonState(favorited: viewModel.isFavorite)
        delegate?.stopDetailViewController(self, didSetFavoritedState: viewModel.isFavorite, forStopID: viewModel.stopID)
    }
    
    func setFavoriteButtonState(favorited favorited: Bool) {
        UIView.animateWithDuration(0.2) {
            self.buttonFavorite.selected = favorited
        }
    }
}