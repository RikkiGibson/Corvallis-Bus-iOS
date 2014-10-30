//
//  ServiceAlertsViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/28/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class ServiceAlertsViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        var url = NSURL(string: "http://www.corvallisoregon.gov/index.aspx?page=1105#pagebody")
        if url != nil {
            webView.loadRequest(NSURLRequest(URL: url!))
        }
        // Do any additional setup after loading the view.
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
