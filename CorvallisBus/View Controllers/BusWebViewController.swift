//
//  BusWebViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import WebKit

final class BusWebViewController: UIViewController, UIGestureRecognizerDelegate, WKNavigationDelegate {
    let webView: WKWebView = WKWebView()
    
    /// Set by the parent to indicate what page the web view should navigate to.
    var initialURL: NSURL?
    var alwaysShowNavigationBar = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let edgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(BusWebViewController.didPanFromEdge(_:)))
        edgePanRecognizer.edges = .Left
        edgePanRecognizer.delegate = self
        
        self.view.addGestureRecognizer(edgePanRecognizer)
        
        let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(BusWebViewController.didTouch(_:)))
        touchRecognizer.numberOfTapsRequired = 1
        touchRecognizer.numberOfTouchesRequired = 1
        touchRecognizer.delegate = self
        
        self.view.addGestureRecognizer(touchRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.navigationDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(webView)
        self.view.addConstraints([
            NSLayoutConstraint(item: self.webView, attribute: .Left, relatedBy: .Equal,
                toItem: self.view, attribute: .Left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .Right, relatedBy: .Equal,
                toItem: self.view, attribute: .Right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .Top, relatedBy: .Equal,
                toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .Bottom, relatedBy: .Equal,
                toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)])
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // necessary if the user begins popping the view controller then pushes it back on
        UIView.animateWithDuration(0.2) {
            self.navigationController?.navigationBarHidden = false
        }
        
        if let url = self.initialURL {
            self.webView.loadRequest(NSURLRequest(URL: url))
        } else {
            fatalError("BusWebViewController should have its initialURL property set before being presented.")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !alwaysShowNavigationBar {
            UIView.animateWithDuration(0.2) {
                self.navigationController?.navigationBarHidden = true
            }
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction,
                 decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.URL else {
            fatalError("navigationAction had a nil URL.")
        }
        guard let initialURL = self.initialURL else {
            fatalError("BusWebViewController.initialURL was unexpectedly nil.")
        }
        
        // For some reason, iPads get redirected to these two places when viewing a route schedule.
        // Accepting the redirect doesn't seem to do anything, so might as well.
        if let path = url.path where path.hasPrefix("/ftp/") {
            decisionHandler(.Allow)
            return
        }
        if url.absoluteString == "about:blank" {
            decisionHandler(.Allow)
            return
        }
        
        // Everything important about the URL except for the hash needs to be the same as the original.
        // This supports users navigating within the page without letting them navigate to another page.
        if url.host == initialURL.host && url.path == initialURL.path && url.query == initialURL.query {
            decisionHandler(.Allow)
        } else {
            decisionHandler(.Cancel)
            presentNavigationActionSheet(url)
        }
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        let javascript = "$(function() {" +
            "$('#show-route-schedules').trigger('click');" +
            "$('#stop-all').trigger('click');" +
            "$('html, body').stop();" +
            "$('html, body').animate({scrollTop: ($('#cts-schedules-top').offset().top)}, 0);" +
        "});"
        
        self.webView.evaluateJavaScript(javascript, completionHandler: nil)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    @IBAction func openInBrowser(sender: AnyObject) {
        if let url = self.initialURL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func presentNavigationActionSheet(url: NSURL) {
        let rect = CGRectMake(self.lastTouchLocation?.x ?? self.view.bounds.size.width / 2.0,
                              self.lastTouchLocation?.y ?? self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        let alertController = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(
            UIAlertAction(title: "Open in Safari", style: .Default) { action in
                UIApplication.sharedApplication().openURL(url); return
            })
        alertController.addAction(
                UIAlertAction(title: "Cancel", style: .Cancel) { action in
            })
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = rect
        
        self.presentViewController(alertController, animated: true) { }
    }
    
    @IBAction func triggerUnwind(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindToMap", sender: self)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func didPanFromEdge(sender: AnyObject) {
        self.performSegueWithIdentifier("unwind", sender: sender)
    }
    
    var lastTouchLocation: CGPoint?
    func didTouch(sender: UITapGestureRecognizer) {
        lastTouchLocation = sender.locationInView(self.view)
    }
}
