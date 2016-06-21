//
//  AppDelegate.swift
//  CorvallisBusMac
//
//  Created by Rikki Gibson on 6/11/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        NSAppleEventManager.sharedAppleEventManager()
                           .setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(_:replyEvent:)),
                                                  forEventClass: AEEventID(kInternetEventClass),
                                                  andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue,
               index = urlString.rangeOfString("?", options: .BackwardsSearch)?.endIndex,
               stopID = Int(urlString.substringFromIndex(index)) {
            // do something with the stop ID
            print(stopID)
        }
    }
}

