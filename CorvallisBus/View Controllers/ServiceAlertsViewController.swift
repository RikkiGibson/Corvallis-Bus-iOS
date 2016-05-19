//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class ServiceAlertsViewController: UITableViewController {
    let dateFormatter = NSDateFormatter()
    let feedParser = ServiceAlertsFeedParserDelegate()
    var items = [MWFeedItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(ServiceAlertsViewController.reloadFeed(_:)), forControlEvents: .ValueChanged)
        
        self.dateFormatter.dateStyle = .LongStyle
        self.dateFormatter.timeStyle = .NoStyle

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadFeed(self);
    }
    
    func reloadFeed(sender: AnyObject) {
        self.feedParser.feedItems() { items in
            self.items = items
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TableViewCell")!
        let item = self.items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.date == nil ? "" : self.dateFormatter.stringFromDate(item.date)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? BusWebViewController ??
            segue.destinationViewController.childViewControllers.first as? BusWebViewController,
            let indexPath = self.tableView.indexPathForSelectedRow {
            destination.initialURL = NSURL(string: self.items[indexPath.row].link)
            destination.alwaysShowNavigationBar = true
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        
    }
}
