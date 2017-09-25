//
//  StopDetailTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

protocol StopDetailViewControllerDelegate : class {
    func stopDetailViewController(_ viewController: StopDetailViewController, didSetFavoritedState favorite: Bool, forStopID stopID: Int)
    func stopDetailViewController(_ viewController: StopDetailViewController, didSelectRouteNamed routeName: String)
    func stopDetailViewController(_ viewController: StopDetailViewController, didSelectDetailsForRouteNamed routeName: String)
    func reloadDetails()
}

final class StopDetailViewController : UITableViewController {
    @IBOutlet weak var labelStopName: UILabel!
    @IBOutlet weak var buttonFavorite: UIButton!
    
    weak var delegate: StopDetailViewControllerDelegate?
    
    private var viewModel = StopDetailViewModel.empty()
    
    lazy var errorPlaceholder: TableViewPlaceholder = {
        let view = Bundle.main.loadNibNamed(
            "TableViewPlaceholder",
            owner: nil,
            options: nil)![0] as! TableViewPlaceholder
        view.labelTitle.text = "Failed to load route details"
        view.button.setTitle("Retry", for: .normal)
        return view
    }()
    
    let CELL_IDENTIFIER = "BusRouteDetailCell"
    override func viewDidLoad() {
        let cellNib = UINib(nibName: CELL_IDENTIFIER, bundle: Bundle.main)
        tableView.register(cellNib, forCellReuseIdentifier: CELL_IDENTIFIER)
        tableView.contentInset = UIEdgeInsets.zero
        updateStopDetails(.success(StopDetailViewModel.empty()))
        errorPlaceholder.handler = { self.delegate?.reloadDetails() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(StopDetailViewController.onOrientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @objc func onOrientationChanged() {
        // Simple workaround to get the label to show text at the right width
        // when the screen orientation goes from landscape to portrait.
        labelStopName.text = viewModel.stopName
    }
    
    func updateStopDetails(_ failable: Failable<StopDetailViewModel, BusError>) {
        guard case .success(let viewModel) = failable else {
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
        buttonFavorite.isEnabled = viewModel.stopID != nil
        
        viewModel.routeDetails.startOnMainThread { failable in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.updateTableView()
            
            if case .success(let routeDetails) = failable, !routeDetails.isEmpty {
                let indexToSelect = didSelectDifferentStop
                    ? IndexPath(row: 0, section: 0)
                    : IndexPath(row: routeDetails.index{ $0.routeName == selectedRouteName } ?? 0, section: 0)
                self.tableView.selectRow(at: indexToSelect, animated: true, scrollPosition: .none)
                self.tableView(self.tableView, didSelectRowAt: indexToSelect)
            }
        }
    }
    
    func clearTableIfDataUnavailable() {
        switch viewModel.routeDetails.state {
        case .finished: break
        default:
            updateTableView()
        }
    }
    
    func updateTableView() {
        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        tableView.endUpdates()
        
        if case .finished(.error) = viewModel.routeDetails.state {
            tableView.backgroundView = errorPlaceholder
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
    
    // MARK: Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if case .finished(.success(let routeDetails)) = viewModel.routeDetails.state {
            return routeDetails.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER) as! BusRouteDetailCell
        
        if case .finished(.success(let routeDetails)) = viewModel.routeDetails.state {
            cell.update(routeDetails[indexPath.row])
        }
        return cell
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .finished(.success(let routeDetails)) = viewModel.routeDetails.state else {
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
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard case .finished(.success(let routeDetails)) = viewModel.routeDetails.state else {
            return
        }
        let routeName = routeDetails[indexPath.row].routeName
        delegate?.stopDetailViewController(self, didSelectDetailsForRouteNamed: routeName)
    }
    
    func setFavoriteButtonState(favorited: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonFavorite.isSelected = favorited
        }) 
    }
}
