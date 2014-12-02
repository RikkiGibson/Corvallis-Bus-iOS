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
    
    var initialRequest: NSURLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.webView.delegate = self
        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Open in Safari", style: .Plain, target: self, action: "openInBrowser:")
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.initialRequest != nil {
            self.webView.loadRequest(self.initialRequest!)
        }
    }
    
    func openInBrowser(sender: AnyObject) {
        if let url = self.webView.request?.URL {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
