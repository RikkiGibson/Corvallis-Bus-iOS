//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class ServiceAlertsViewController: UITableViewController, UIWebViewDelegate {
    let webViewController = UIViewController()
    let dateFormatter = NSDateFormatter()
    let feedParser = ServiceAlertsFeedParserDelegate()
    var items = [MWFeedItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "reloadFeed:", forControlEvents: .ValueChanged)
        
        let webView = UIWebView()
        webView.delegate = self
        self.webViewController.view = webView
        self.webViewController.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Open in Safari", style: .Plain, target: self, action: "openInBrowser:")
        
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
        let cell = tableView.dequeueReusableCellWithIdentifier("TableViewCell") as UITableViewCell
        let item = self.items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.date == nil ? "" : self.dateFormatter.stringFromDate(item.date)
        
        return cell
    }
    
    func openInBrowser(sender: AnyObject) {
        if let webView = self.webViewController.view as? UIWebView {
            if let url = webView.request?.URL {
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }
    
    /**
        Causes Safari to be opened if a link is tapped.
    */
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            UIApplication.sharedApplication().openURL(request.URL)
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let url = NSURL(string: self.items[indexPath.row].link) {
            if let webView = self.webViewController.view as? UIWebView {
                webView.loadRequest(NSURLRequest(URL: url))
                self.navigationController?.pushViewController(self.webViewController, animated: true)
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
}
