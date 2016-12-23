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
    lazy var placeholder: FavoritesPlaceholder = Bundle.main.loadNibNamed(
            "FavoritesPlaceholder",
            owner: nil,
            options: nil)![0] as! FavoritesPlaceholder
    
    var favoriteStops = [FavoriteStopViewModel]()
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder.handler = self.goToBrowseController
        
        let cellNib = UINib(nibName: "FavoritesTableViewCell", bundle: Bundle.main)
        self.tableView.register(cellNib, forCellReuseIdentifier: "FavoritesTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(FavoritesTableViewController.updateFavorites), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesTableViewController.updateFavorites),
            name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(FavoritesTableViewController.updateFavorites),
            userInfo: nil, repeats: true)
        
        updateFavorites()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        timer?.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let defaults = UserDefaults.groupUserDefaults()
        if !defaults.hasPreviouslyLaunched {
            defaults.hasPreviouslyLaunched = true
            presentWelcomeDialog()
        }
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
            UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in }))
        
        self.present(alertController, animated: true) { }
    }
    
    func goToBrowseController() {
        guard let browseViewController: BrowseViewController = tabBarController!.childViewController() else {
            fatalError("Browse view controller not present as expected")
        }
        tabBarController!.selectedViewController = browseViewController.navigationController
    }
    
    func updateFavorites() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        CorvallisBusFavoritesManager.favoriteStopsForApp()
            .startOnMainThread(onUpdate)
    }
    
    func onUpdate(_ result: Failable<[FavoriteStopViewModel], BusError>) {
        favoriteStops = result ?? []
        
        self.refreshControl?.endRefreshing()
        
        self.tableView.reloadData()
        self.reconfigureTableView()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if case .error(.message(let message)) = result {
            presentError(message)
        }
    }
    
    func reconfigureTableView() {
        if favoriteStops.isEmpty {
            self.tableView.backgroundView = placeholder
            self.tableView.separatorStyle = .none
        } else {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = .singleLine
        }
        
        self.navigationItem.rightBarButtonItem = favoriteStops.any({ !$0.isNearestStop })
            ? self.editButtonItem
            : nil
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favoriteStops.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesTableViewCell", for: indexPath) as! FavoriteStopTableViewCell
        
        cell.update(favoriteStops[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let selectedStop = self.favoriteStops[indexPath.row]
        return !selectedStop.isNearestStop
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            // Delete the row from the data source
            favoriteStops.remove(at: indexPath.row)
            
            let userDefaults = UserDefaults.groupUserDefaults()
            userDefaults.favoriteStopIds = favoriteStops.filter{ !$0.isNearestStop }.map{ $0.stopId }
            
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
        browseViewController.selectStopExternally(favoriteStops[indexPath.row].stopId)
        tabBarController!.selectedViewController = browseViewController.navigationController
    }
}
