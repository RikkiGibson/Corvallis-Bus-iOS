//
//  ServiceAlertsManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/26/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

final class ServiceAlertsManager : NSObject, MWFeedParserDelegate {
    private let parser = MWFeedParser(feedURL: URL(string: "https://www.corvallisoregon.gov/Rss.aspx?type=5&cat=100,104,105,106,107,108,109,110,111,112,113,114,58,119&dept=12&paramtime=Current")!)
    
    private var items: [MWFeedItem] = []
    private var callback: (Failable<[ServiceAlert], BusError>) -> Void = { items in }
    
    override init() {
        super.init()
        
        parser?.delegate = self
        parser?.feedParseType = ParseTypeItemsOnly
        parser?.connectionType = ConnectionTypeAsynchronously
    }
    
    func serviceAlerts(_ callback: @escaping (Failable<[ServiceAlert], BusError>) -> Void) {
        self.callback = callback
        items = []
        parser?.parse()
    }
    
    func toggleRead(_ alert: ServiceAlert) -> ServiceAlert {
        let defaults = UserDefaults.groupUserDefaults()
        var seenIdentifiers = defaults.seenServiceAlertIds
        if alert.isRead {
            seenIdentifiers.remove(alert.identifier)
        } else {
            seenIdentifiers.insert(alert.identifier)
        }
        
        defaults.seenServiceAlertIds = seenIdentifiers
        var newAlert = alert
        newAlert.isRead = !newAlert.isRead
        return newAlert
    }
    
    func markRead(_ alert: ServiceAlert) -> ServiceAlert {
        if alert.isRead {
            return alert
        }
        
        let defaults = UserDefaults.groupUserDefaults()
        var seenIdentifiers = defaults.seenServiceAlertIds
        seenIdentifiers.insert(alert.identifier)
        defaults.seenServiceAlertIds = seenIdentifiers
        
        var newAlert = alert
        newAlert.isRead = true
        return newAlert
    }
    
    func feedParser(_ parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        items.append(item)
    }
    
    func feedParserDidFinish(_ parser: MWFeedParser!) {        
        let defaults = UserDefaults.groupUserDefaults()
        let seenIds = defaults.seenServiceAlertIds
        
        let alerts = self.items.map({ item in
            ServiceAlert.fromMWFeedItem(feedItem: item, isRead: seenIds.contains(item.identifier))
        })
        self.callback(.success(alerts))
    }
    
    func feedParser(_ parser: MWFeedParser!, didFailWithError error: Error!) {
        self.callback(.error(.message(error.localizedDescription)))
    }
}
