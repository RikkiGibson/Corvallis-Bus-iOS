//
//  AppDelegate.swift
//  CorvallisBusMac
//
//  Created by Rikki Gibson on 6/11/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa

protocol StopSelectionDelegate : class {
    func onStopSelected(stopID: Int)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private static var externalStopID: Int?
    
    weak static var stopSelectionDelegate: StopSelectionDelegate?
    
    override init() {
        super.init()
        
        NSAppleEventManager.sharedAppleEventManager()
            .setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(_:replyEvent:)),
                             forEventClass: AEEventID(kInternetEventClass),
                             andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue,
               index = urlString.rangeOfString("?", options: .BackwardsSearch)?.endIndex,
               stopID = Int(urlString.substringFromIndex(index)) {
            // do something with the stop ID
            if let stopSelectionDelegate = AppDelegate.stopSelectionDelegate {
                stopSelectionDelegate.onStopSelected(stopID)
            } else {
                AppDelegate.externalStopID = stopID
            }
        }
    }
    
    static func dequeueSelectedStopID() -> Int? {
        let stopID = externalStopID
        externalStopID = nil
        return stopID
    }
}
