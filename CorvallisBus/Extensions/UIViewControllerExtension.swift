//
//  UIViewControllerExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/5/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { action in })
        self.present(alertController, animated: true) { }
    }
    
    func presentError(_ message: String) {
        presentAlert(title: "Error", message: message)
    }
    
    func presentURL(_ url: URL) {
        guard let destination = storyboard?.instantiateViewController(withIdentifier: "WebNavigation") as? UINavigationController else {
            fatalError("Tried to present URL while not attached to a storyboard with a view controller with identifier WebNavigation")
        }

        let webVC = destination.children.first as! BusWebViewController
        webVC.initialURL = url
        webVC.alwaysShowNavigationBar = true
        
        self.present(destination, animated: true, completion: nil)
    }
}
