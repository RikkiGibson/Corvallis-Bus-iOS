//
//  BusWebViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class BusWebViewController: UIViewController, UIWebViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    var initialURL: NSURL?
    var alwaysShowNavigationBar = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let edgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "didPanFromEdge:")
        edgePanRecognizer.edges = .Left
        edgePanRecognizer.delegate = self
        
        self.view.addGestureRecognizer(edgePanRecognizer)
        
        let touchRecognizer = UITapGestureRecognizer(target: self, action: "didTouch:")
        touchRecognizer.numberOfTapsRequired = 1
        touchRecognizer.numberOfTouchesRequired = 1
        touchRecognizer.delegate = self
        
        self.view.addGestureRecognizer(touchRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // necessary if the user begins popping the view controller then pushes it back on
        UIView.animateWithDuration(0.2) {
            self.navigationController?.navigationBarHidden = false
            return
        }
        
        if self.initialURL != nil {
            self.webView.loadRequest(NSURLRequest(URL: self.initialURL!))
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !alwaysShowNavigationBar {
            UIView.animateWithDuration(0.2) {
                self.navigationController?.navigationBarHidden = true
                return
            }
        }
    }
    
    @IBAction func openInBrowser(sender: AnyObject) {
        if let url = self.webView.request?.URL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func triggerUnwind(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindToMap", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // An instance variable is needed to keep track of the URL request
    // between creation of the UIActionSheet and the callback invocation.
    private var leadingRequest: NSURLRequest?
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if navigationType != .LinkClicked || webView.request?.URL?.query == request.URL?.query {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            return true
        } else {
            let rect = CGRectMake(self.lastTouchLocation?.x ?? self.view.bounds.size.width / 2.0,
                self.lastTouchLocation?.y ?? self.view.bounds.size.height / 2.0, 1.0, 1.0)
            
            // iOS 8
            if let url = request.URL where UIAlertControllerWorkaround.deviceDoesSupportUIAlertController() {
                let alertController = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .ActionSheet)
                alertController.addAction(UIAlertAction(title: "Open in Safari", style: .Default) { action in
                    UIApplication.sharedApplication().openURL(url); return
                })
                alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { action in })
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = rect
                self.presentViewController(alertController, animated: true) { }
            } else { // iOS 7
                self.leadingRequest = request
                let actionSheet = UIActionSheet(title: request.URL?.absoluteString, delegate: self,
                    cancelButtonTitle: nil, destructiveButtonTitle: nil)
                actionSheet.addButtonWithTitle("Open in Safari")
                actionSheet.addButtonWithTitle("Cancel")
                actionSheet.cancelButtonIndex = 1
                
                actionSheet.showFromRect(rect, inView: self.view, animated: true)
            }
            return false
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if let url = leadingRequest?.URL where buttonIndex == 0 {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let javascript = "$(function() {" +
                "$('#show-route-schedules').trigger('click');" +
                "$('#stop-all').trigger('click');" +
                "$('html, body').stop();" +
                "$('html, body').animate({scrollTop: ($('#cts-schedules-top').offset().top)}, 0);" +
            "});"
        webView.stringByEvaluatingJavaScriptFromString(javascript)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
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
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
