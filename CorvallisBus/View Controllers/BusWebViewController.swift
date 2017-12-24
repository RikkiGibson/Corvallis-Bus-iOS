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
    var initialURL: URL?
    var alwaysShowNavigationBar = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let edgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(BusWebViewController.didPanFromEdge(_:)))
        edgePanRecognizer.edges = .left
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
            NSLayoutConstraint(item: self.webView, attribute: .left, relatedBy: .equal,
                toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .right, relatedBy: .equal,
                toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .top, relatedBy: .equal,
                toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.webView, attribute: .bottom, relatedBy: .equal,
                toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0.0)])
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // necessary if the user begins popping the view controller then pushes it back on
        UIView.animate(withDuration: 0.2, animations: {
            self.navigationController?.isNavigationBarHidden = false
        }) 
        
        if let url = self.initialURL {
            self.webView.load(URLRequest(url: url))
        } else {
            fatalError("BusWebViewController should have its initialURL property set before being presented.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !alwaysShowNavigationBar {
            UIView.animate(withDuration: 0.2, animations: {
                self.navigationController?.isNavigationBarHidden = true
            }) 
        }
    }
    
    @IBAction func onBackButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            fatalError("navigationAction had a nil URL.")
        }
        guard let initialURL = self.initialURL else {
            fatalError("BusWebViewController.initialURL was unexpectedly nil.")
        }
        
        // For some reason, iPads get redirected to these two places when viewing a route schedule.
        // Accepting the redirect doesn't seem to do anything, so might as well.
        if url.path.hasPrefix("/ftp/") {
            decisionHandler(.allow)
            return
        }
        if url.absoluteString == "about:blank" {
            decisionHandler(.allow)
            return
        }
        
        // Everything important about the URL except for the hash needs to be the same as the original.
        // This supports users navigating within the page without letting them navigate to another page.
        if url.host == initialURL.host && url.path == initialURL.path && url.query == initialURL.query {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            presentNavigationActionSheet(url)
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    @IBAction func openInBrowser(_ sender: AnyObject) {
        if let url = self.initialURL {
            UIApplication.shared.openURL(url)
        }
    }
    
    func presentNavigationActionSheet(_ url: URL) {
        let rect = CGRect(x: self.lastTouchLocation?.x ?? self.view.bounds.size.width / 2.0,
                              y: self.lastTouchLocation?.y ?? self.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        let alertController = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "Open in Safari", style: .default) { action in
                UIApplication.shared.openURL(url); return
            })
        alertController.addAction(
                UIAlertAction(title: "Cancel", style: .cancel) { action in
            })
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = rect
        
        self.present(alertController, animated: true) { }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func didPanFromEdge(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var lastTouchLocation: CGPoint?
    @objc func didTouch(_ sender: UITapGestureRecognizer) {
        lastTouchLocation = sender.location(in: self.view)
    }
}
