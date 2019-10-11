//
//  FavoritesTableViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/17/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import MapKit

final class FavoritesTableViewController: UITableViewController {
    lazy var placeholder: TableViewPlaceholder = {
        let view = Bundle.main.loadNibNamed(
            "TableViewPlaceholder",
            owner: nil,
            options: nil)![0] as! TableViewPlaceholder
        view.labelTitle.text = "Add frequently used stops to Favorites."
        view.button.setTitle("Tap to browse stops", for: .normal)
        
        return view
    }()
    
    lazy var errorPlaceholder: TableViewPlaceholder = {
        let view = Bundle.main.loadNibNamed(
            "TableViewPlaceholder",
            owner: nil,
            options: nil)![0] as! TableViewPlaceholder
        view.labelTitle.text = "Failed to load favorites"
        view.button.setTitle("Retry", for: .normal)
        return view
    }()
    
    var favoriteStops: Resource<[FavoriteStopViewModel], BusError> = .loading
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder.handler = self.goToBrowseController
        errorPlaceholder.handler = self.updateFavorites
        
        let cellNib = UINib(nibName: "FavoritesTableViewCell", bundle: Bundle.main)
        self.tableView.register(cellNib, forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(FavoritesTableViewController.updateFavorites), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesTableViewController.updateFavorites),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(FavoritesTableViewController.updateFavorites),
            userInfo: nil, repeats: true)
        
        let defaults = UserDefaults.groupUserDefaults()
        if defaults.hasPreviouslyLaunched {
            updateFavorites()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = UserDefaults.groupUserDefaults()
        if !defaults.hasPreviouslyLaunched {
            defaults.hasPreviouslyLaunched = true
            presentWelcomeDialog()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        timer?.invalidate()
    }
    
    func presentWelcomeDialog() {
        let alertController = UIAlertController(
            title: "Welcome to Corvallis Bus",
            message: "Check out the user guide for tips on how to get started, or view it later in Preferences.",
            preferredStyle: .alert)
        
        alertController.addAction(
            UIAlertAction(title: "View User Guide", style: .default) { action in
                self.presentURL(URL(string: "https://rikkigibson.github.io/corvallisbus/ios-user-guide/index.html")!)
            })
        
        alertController.addAction(
            UIAlertAction(title: "Dismiss", style: .cancel) { action in
                self.updateFavorites()
            })
        
        self.present(alertController, animated: true) { }
    }
    
    func goToBrowseController() {
        guard let browseViewController: BrowseViewController = tabBarController!.childViewController() else {
            fatalError("Browse view controller not present as expected")
        }
        tabBarController!.selectedViewController = browseViewController.navigationController
    }
    
    @objc func updateFavorites() {
        self.refreshControl?.beginRefreshing()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        CorvallisBusFavoritesManager.favoriteStopsForApp()
            .startOnMainThread(onUpdate)
    }
    
    func onUpdate(_ result: Failable<[FavoriteStopViewModel], BusError>) {
        favoriteStops = Resource.fromFailable(result)
        
        self.refreshControl?.endRefreshing()
        
        self.tableView.reloadData()
        self.reconfigureTableView()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func reconfigureTableView() {
        if case .loading = favoriteStops {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .none
            self.navigationItem.rightBarButtonItem = nil
        }
        else if case .error = favoriteStops {
            self.tableView.backgroundView = errorPlaceholder
            self.tableView.separatorStyle = .none
            self.navigationItem.rightBarButtonItem = nil
        } else if case .success(let models) = favoriteStops {
            if models.isEmpty {
                self.tableView.backgroundView = placeholder
                self.tableView.separatorStyle = .none
            } else {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
            }
            
            self.navigationItem.rightBarButtonItem = models.any({ !$0.isNearestStop })
                ? self.editButtonItem
                : nil
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.favoriteStops ?? []).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard case .success(let models) = self.favoriteStops else {
            fatalError("Table view asked for cell when no models were present")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesTableViewCell", for: indexPath) as! FavoriteStopTableViewCell
        
        cell.update(models[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard case .success(let models) = self.favoriteStops else {
            fatalError("Table view asked for cell when no models were present")
        }
        let selectedStop = models[indexPath.row]
        return !selectedStop.isNearestStop
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard case .success(let models) = self.favoriteStops else {
            fatalError("Table view asked for cell when no models were present")
        }
        
        if editingStyle == .delete {
            var newModels = models
            newModels.remove(at: indexPath.row)
            self.favoriteStops = .success(newModels)
            
            let userDefaults = UserDefaults.groupUserDefaults()
            userDefaults.favoriteStopIds = newModels.filter{ !$0.isNearestStop }.map{ $0.stopId }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        reconfigureTableView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let browseViewController: BrowseViewController = tabBarController!.childViewController() else {
            fatalError("Browse view controller not present as expected")
        }
        guard case .success(let models) = favoriteStops else {
            fatalError("Selected row when no models were present")
        }

        browseViewController.selectStopExternally(models[indexPath.row].stopId)
        tabBarController!.selectedViewController = browseViewController.navigationController
    }
}
