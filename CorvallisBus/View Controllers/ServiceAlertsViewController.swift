//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class ServiceAlertsViewController: UITableViewController {
    let manager = ServiceAlertsManager()
    var alerts: Resource<[ServiceAlert], BusError> = .loading
    
    lazy var placeholder: TableViewPlaceholder = {
        let view = Bundle.main.loadNibNamed(
            "TableViewPlaceholder",
            owner: nil,
            options: nil)![0] as! TableViewPlaceholder
        view.labelTitle.text = "No current service alerts."
        view.button.setTitle("Tap to open service alerts website", for: .normal)
        
        return view
    }()
    
    lazy var errorPlaceholder: TableViewPlaceholder = {
        let view = Bundle.main.loadNibNamed(
            "TableViewPlaceholder",
            owner: nil,
            options: nil)![0] as! TableViewPlaceholder
        view.labelTitle.text = "Failed to load service alerts"
        view.button.setTitle("Retry", for: .normal)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeholder.handler = { self.presentURL(URL(string: "https://www.corvallisoregon.gov/index.aspx?page=1105")!) }
        self.errorPlaceholder.handler = self.reloadAlerts
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ServiceAlertsViewController.reloadAlerts), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadAlerts()
    }
    
    func reloadAlerts() {
        self.refreshControl?.beginRefreshing()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        self.manager.serviceAlerts(onAlertsReloaded)
    }
    
    func onAlertsReloaded(alerts: Failable<[ServiceAlert], BusError>) {
        self.alerts = Resource.fromFailable(alerts)
        self.tableView.reloadData()
        
        if case .success(let models) = alerts {
            if models.isEmpty {
                self.tableView.backgroundView = placeholder
                self.tableView.separatorStyle = .none
            } else {
                self.tableView.backgroundView = nil
                self.tableView.separatorStyle = .singleLine
            }
        } else {
            self.tableView.backgroundView = errorPlaceholder
            self.tableView.separatorStyle = .none
        }
        
        self.updateBadgeValue()
        self.refreshControl?.endRefreshing()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false

    }
    
    func updateBadgeValue() {
        guard case .success(let models) = self.alerts else {
            self.navigationController?.tabBarItem.badgeValue = nil
            return
        }
        
        var unreadCount = 0
        for alert in models {
            if !alert.isRead {
                unreadCount += 1
            }
        }
        
        if unreadCount == 0 {
            self.navigationController?.tabBarItem.badgeValue = nil
        } else {
            self.navigationController?.tabBarItem.badgeValue = String(unreadCount)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.alerts = .loading
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (alerts ?? []).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard case .success(let models) = self.alerts else {
            fatalError("Table view asked for cell when no models were present")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceAlertCell", for: indexPath) as! ServiceAlertCell
        let alert = models[indexPath.row]
        
        cell.update(with: alert)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard case .success(let models) = self.alerts else {
            fatalError("Table view asked for cell when no models were present")
        }
        
        let isRead = models[indexPath.row].isRead
        let action = UITableViewRowAction(style: .normal, title: isRead ? "Mark\nUnread" : "Mark\nRead") { action, indexPath in
            var newModels = models
            newModels[indexPath.row] = self.manager.toggleRead(newModels[indexPath.row])
            self.alerts = .success(newModels)
            
            self.tableView.setEditing(false, animated: true)
            
            let cell = self.tableView.cellForRow(at: indexPath) as! ServiceAlertCell
            cell.update(with: newModels[indexPath.row])

            self.updateBadgeValue()
        }
        action.backgroundColor = UIColor(colorLiteralRed: 0, green: 122/255, blue: 255/255, alpha: 1)
        return [action]
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .success(let models) = self.alerts else {
            fatalError("Table view asked for cell when no models were present")
        }
        
        var newModels = models
        newModels[indexPath.row] = self.manager.markRead(newModels[indexPath.row])
        self.alerts = .success(newModels)
        
        let urlString = newModels[indexPath.row].url
        if let url = URL(string: urlString) {
            presentURL(url)
        } else {
            presentError("Unable to open URL: \(urlString)")
        }
    }
}
