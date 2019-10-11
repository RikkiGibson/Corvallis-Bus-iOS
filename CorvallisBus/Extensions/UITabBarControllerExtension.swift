//
//  UITabBarControllerExtension.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 8/29/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import UIKit

extension UITabBarController {
    func selectBrowseViewController() -> BrowseViewController {
        // This will break if the order of items in the tab bar controller is changed.
        // The alternatives involve poking at the navigation controllers that contain these,
        // so it really doesn't seem like a meaningful reduction in effort.
        selectedIndex = 1
        return (selectedViewController as? BrowseViewController ??
            selectedViewController?.children.last as? BrowseViewController)!
    }
    
    func childViewController<T: UIViewController>() -> T? {
        for childViewController in children {
            if let childViewController = childViewController as? T ??
                childViewController.children.first({ $0 is T }) as? T {
                    return childViewController
            }
        }
        return nil
    }
}
