//
//  UIViewControllerExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/5/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import UIKit
import SafariServices

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
        let safariVC = SFSafariViewController(url: url)
        self.present(safariVC, animated: true, completion: nil)
    }
}
