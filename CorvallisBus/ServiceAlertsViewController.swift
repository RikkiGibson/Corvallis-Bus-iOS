//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class ServiceAlertsViewController: UITableViewController, MWFeedParserDelegate {
    var parser: MWFeedParser?
    var items = [MWFeedItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        if let url = NSURL(string: "http://www.corvallisoregon.gov/Rss.aspx?type=5&cat=100,104,105,106,107,108,109,110,111,112,113,114,58,119&dept=12&paramtime=Current") {
            self.items = [MWFeedItem]()
            
            self.parser = MWFeedParser(feedURL: url)
            self.parser!.delegate = self
            self.parser!.feedParseType = ParseTypeItemsOnly
            self.parser!.connectionType = ConnectionTypeAsynchronously
            self.parser!.parse()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        items.append(item)
    }
    
    func feedParserDidFinish(parser: MWFeedParser!) {
        if items.count == 0 {
            let item = MWFeedItem()
            item.title = "No current service alerts!\nTouch to view the service alerts website"
            item.link = "http://www.corvallisoregon.gov/index.aspx?page=1105"
            items.append(item)
        }
        self.tableView.reloadData()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("ServiceAlertCell") as ServiceAlertTableViewCell

        cell.labelTitle.text = self.items[indexPath.row].title
        cell.labelDescription.text = self.items[indexPath.row].summary
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let url = NSURL(string: self.items[indexPath.row].link) {
            UIApplication.sharedApplication().openURL(url)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}
