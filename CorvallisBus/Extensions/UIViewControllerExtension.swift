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
        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Default) { action in })
            self.presentViewController(alertController, animated: true) { }
        } else {
            let alertView = UIAlertView(title: title, message: message,
                delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok")
            alertView.show()
        }
    }
    
    func presentError(message: String) {
        presentAlert(title: "Error", message: message)
    }
    
    func presentTutorial() {
        let storyboard = UIStoryboard(name: "Tutorial", bundle: nil)
        let tutorialViewController = storyboard.instantiateInitialViewController()!
        
        navigationController?.presentViewController(tutorialViewController, animated: true, completion: { })
    }
}