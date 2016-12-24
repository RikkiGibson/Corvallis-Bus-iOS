//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class ServiceAlertsViewController: UITableViewController {
    let dateFormatter = DateFormatter()
    let feedParser = ServiceAlertsFeedParserDelegate()
    var items = [MWFeedItem]()
    var unseenIdentifiers: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ServiceAlertsViewController.reloadFeed(_:)), for: .valueChanged)

        self.dateFormatter.dateStyle = .long
        self.dateFormatter.timeStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadFeed(self);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.tabBarItem.badgeValue = nil
    }
    
    func reloadFeed(_ sender: AnyObject) {
        self.feedParser.feedItems(onFeedReloaded)
    }
    
    func onFeedReloaded(items: [MWFeedItem]) {
        self.items = items
        self.tableView.reloadData()
        
        let defaults = UserDefaults.groupUserDefaults()
        let prevSeen = defaults.seenServiceAlertIds
        
        let identifiers = Set(self.items.mapUnwrap({ $0.identifier }))
        
        self.unseenIdentifiers = identifiers.subtracting(prevSeen)
        if self.unseenIdentifiers.isEmpty {
            self.navigationController?.tabBarItem.badgeValue = nil
        } else {
            self.navigationController?.tabBarItem.badgeValue = String(self.unseenIdentifiers.count)
        }
        
        defaults.seenServiceAlertIds = prevSeen.union(self.unseenIdentifiers)
        
        self.refreshControl?.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        items = []
        unseenIdentifiers = []
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceAlertCell", for: indexPath) as! ServiceAlertCell
        let item = self.items[indexPath.row]
        cell.titleLabel?.text = item.title
        cell.descriptionLabel?.text = item.date == nil ? "" : self.dateFormatter.string(from: item.date)
        cell.imageUnread.isHidden = !self.unseenIdentifiers.contains(item.identifier)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let isRowUnseen = unseenIdentifiers.contains(self.items[indexPath.row].identifier)
        let action = UITableViewRowAction(style: .normal, title: isRowUnseen ? "Mark as Read" : "Mark as Unread") { action, indexPath in
            let item = self.items[indexPath.row]
            let identifier = item.identifier!
            if self.unseenIdentifiers.contains(identifier) {
                self.unseenIdentifiers.remove(identifier)
            } else {
                self.unseenIdentifiers.insert(identifier)
            }
            self.tableView.setEditing(false, animated: true)
            
            let cell = self.tableView.cellForRow(at: indexPath) as! ServiceAlertCell
            cell.imageUnread.isHidden = !self.unseenIdentifiers.contains(item.identifier)
        }
        return [action]
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let link = self.items[indexPath.row].link
        if let url = URL(string: link!) {
            presentURL(url)
        } else {
            presentError("Unable to open URL: \(link)")
        }
    }
}
