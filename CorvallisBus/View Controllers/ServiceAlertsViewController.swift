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
    var alerts: [ServiceAlert] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ServiceAlertsViewController.reloadAlerts(_:)), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadAlerts(self);
    }
    
    func reloadAlerts(_ sender: AnyObject) {
        self.manager.serviceAlerts(onAlertsReloaded)
    }
    
    func onAlertsReloaded(alerts: [ServiceAlert]) {
        self.alerts = alerts
        self.tableView.reloadData()
        self.updateBadgeValue()
        self.refreshControl?.endRefreshing()
    }
    
    func updateBadgeValue() {
        var unreadCount = 0
        for alert in self.alerts {
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
        alerts = []
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alerts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceAlertCell", for: indexPath) as! ServiceAlertCell
        let alert = self.alerts[indexPath.row]
        
        cell.update(with: alert)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let isRead = self.alerts[indexPath.row].isRead
        let action = UITableViewRowAction(style: .normal, title: isRead ? "Mark\nUnread" : "Mark\nRead") { action, indexPath in
            self.alerts[indexPath.row] = self.manager.toggleRead(self.alerts[indexPath.row])
            
            self.tableView.setEditing(false, animated: true)
            
            let cell = self.tableView.cellForRow(at: indexPath) as! ServiceAlertCell
            cell.update(with: self.alerts[indexPath.row])

            self.updateBadgeValue()
        }
        action.backgroundColor = UIColor(colorLiteralRed: 0, green: 122/255, blue: 255/255, alpha: 1)
        return [action]
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.alerts[indexPath.row] = self.manager.markRead(self.alerts[indexPath.row])
        
        let urlString = self.alerts[indexPath.row].url
        if let url = URL(string: urlString) {
            presentURL(url)
        } else {
            presentError("Unable to open URL: \(urlString)")
        }
    }
}
