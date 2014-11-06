//
//  AppDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        /*
        Parse.setApplicationId("9opwF8DAywRM4AZuDPoZ5u9jvajZdgxkU36uYnCm", clientKey: "czS3p99OeIan69n8etH37NRm7Hs9mYfaJWXK8a3u")
        
        // iOS 8
        if application.respondsToSelector("registerUserNotificationSettings:") {
            var settings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else { // iOS 7
            application.registerForRemoteNotificationTypes(.Badge | .Alert | .Sound)
        }
        */
        
        return true
    }
    
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        CorvallisBusService.stops() { stops in
            dispatch_async(dispatch_get_main_queue()) {
                // Some really gnarly conditional bindings in here.
                if let tabController = self.window?.rootViewController as? UITabBarController {
                    tabController.selectedIndex = 1 // selects map tab
                    
                    // before the ?? is for iOS 7. After the ?? is for iOS 8
                    if let viewController = tabController.selectedViewController as? StopsMapViewController ?? tabController.selectedViewController?.childViewControllers.last as? StopsMapViewController {
                        if let id = url.query?.toInt() {
                            viewController.initialStop = stops.first() { $0.id == id }
                        }
                    }
                }
            }
        }
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        /*
        var currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackgroundWithBlock() { succeeded, error in
            if error != nil {
                currentInstallation.saveEventually()
            }
        }
        */
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        //PFPush.handlePush(userInfo)
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

