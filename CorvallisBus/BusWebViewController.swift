//
//  BusWebViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class BusWebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    var initialURL: NSURL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        
        self.performSegueWithIdentifier("unwindMap", sender: self)
        UIView.animateWithDuration(0.2) {
            self.navigationController?.navigationBarHidden = true
            return
        }
    }
    
    @IBAction func openInBrowser(sender: AnyObject) {
        if let url = self.webView.request?.URL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType != .LinkClicked || webView.request?.URL.query == request.URL.query {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            return true
        } else {
            UIApplication.sharedApplication().openURL(request.URL)
            return false
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
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
