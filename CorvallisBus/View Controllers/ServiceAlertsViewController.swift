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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ServiceAlertsViewController.reloadFeed(_:)), for: .valueChanged)
        
        self.dateFormatter.dateStyle = .long
        self.dateFormatter.timeStyle = .none

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadFeed(self);
    }
    
    func reloadFeed(_ sender: AnyObject) {
        self.feedParser.feedItems() { items in
            self.items = items
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        items = []
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell")!
        let item = self.items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.date == nil ? "" : self.dateFormatter.string(from: item.date)
        
        return cell
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
