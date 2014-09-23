//
//  SecondViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import Foundation

class SecondViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getRoutes()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getRoutes() {
        var session = NSURLSession.sharedSession()
        session.dataTaskWithURL(NSURL(string: "http://www.corvallis-bus.appspot.com/stops"),
        completionHandler: {
            (data, response, error) -> Void in
            if (error != nil) {
                println(error.description)
            }
            
            var jsonError: NSError?
            var stops = NSJSONSerialization.JSONObjectWithData(data,
                options: NSJSONReadingOptions.AllowFragments,
                error: &jsonError)?.objectForKey("stops") as NSArray as Array<Dictionary<String, AnyObject>>
            
            stops.map() { dict -> BusStop in BusStop(json: dict) }
            
//            var stopObjects = Array<BusStop>()
//            for stop in stops {
//                stopObjects.append(BusStop(json: stop))
//            }
        }).resume()
        
    }
    
}

