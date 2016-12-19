//
//  UIStoryboardSegueExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/23/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension UIStoryboardSegue {
    /// This wraps up the boilerplate around the fact that iOS 7 wants
    /// to provide the navigation controller as the destination view controller.
    func getContentViewController<T: UIViewController>() -> T? {
        if let contentViewController = destination as? T {
            return contentViewController
        }
        return destination.childViewControllers.first{ $0 is T } as? T
    }
}
