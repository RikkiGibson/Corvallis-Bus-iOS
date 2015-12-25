//
//  AppDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Populate static data cache
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue) {
            CorvallisBusManager().staticData().start{ result in }
        }
        Flurry.startSession("XW65DQFD4RKR9WHP6QC3")
        
        return true
    }
    
    /// Selects the map tab in the tab controller and returns the map view controller.
    private func getViewPreparedForStop() -> BrowseViewController {
        let tabController = self.window!.rootViewController as! UITabBarController
        // TODO: provide the browse view controller instance instead of selecting the index
        tabController.selectedIndex = 1 // selects map tab
        return (tabController.selectedViewController as? BrowseViewController ??
            tabController.selectedViewController?.childViewControllers.last as? BrowseViewController)!
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        guard let query = url.query, stopID = Int(query) else {
            return false
        }
        
        let tabBarController = self.window!.rootViewController as! UITabBarController
        guard let browseViewController: BrowseViewController = tabBarController.childViewController() else {
            fatalError("Browse view controller not present as expected.")
        }
        tabBarController.selectedViewController = browseViewController.navigationController
        browseViewController.selectStopExternally(stopID)
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

