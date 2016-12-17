//
//  UIViewControllerExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/5/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension UIViewController {
    func presentAlert(title title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { action in })
        self.presentViewController(alertController, animated: true) { }
    }
    
    func presentError(message: String) {
        presentAlert(title: "Error", message: message)
    }
    
    func presentURL(url: NSURL) {
        guard let destination = storyboard?.instantiateViewControllerWithIdentifier("WebNavigation") as? UINavigationController else {
            fatalError("Tried to present URL while not attached to a storyboard with a view controller with identifier WebNavigation")
        }
        let webVC = destination.childViewControllers.first as! BusWebViewController
        webVC.initialURL = url
        webVC.alwaysShowNavigationBar = true
        
        self.presentViewController(destination, animated: true, completion: nil)
    }
}
