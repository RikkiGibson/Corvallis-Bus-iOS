//
//  AppDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

// TODO: it's really weird for this to be here. where is a better place?
let USER_INFO_STOP_ID_KEY = "stopID"

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Populate static data cache
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            CorvallisBusManager().staticData().start{ result in }
        }
        
        #if RELEASE
            Flurry.startSession("XW65DQFD4RKR9WHP6QC3")
        #else
            print("Not a release build. Flurry is not running.")
        #endif
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        
        let tabBarController = self.window!.rootViewController as! UITabBarController
        guard let browseViewController: BrowseViewController = tabBarController.childViewController() else {
            fatalError("Browse view controller not present as expected.")
        }
        
        if let stopID = userActivity.userInfo?[USER_INFO_STOP_ID_KEY] as? Int ??
                        userActivity.webpageURL?.fragment.flatMap({ Int($0) }) {
            tabBarController.selectedViewController = browseViewController.navigationController
            browseViewController.selectStopExternally(stopID)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        guard let query = url.query, let stopID = Int(query) else {
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

