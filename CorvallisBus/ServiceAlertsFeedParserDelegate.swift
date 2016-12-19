//
//  ServiceAlertsFeedParserDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/26/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

final class ServiceAlertsFeedParserDelegate : NSObject, MWFeedParserDelegate {
    private let parser = MWFeedParser(feedURL: URL(string: "https://www.corvallisoregon.gov/Rss.aspx?type=5&cat=100,104,105,106,107,108,109,110,111,112,113,114,58,119&dept=12&paramtime=Current")!)
    
    private var items: [MWFeedItem] = []
    private var callback: ([MWFeedItem]) -> Void = { items in }
    
    override init() {
        super.init()
        
        parser?.delegate = self
        parser?.feedParseType = ParseTypeItemsOnly
        parser?.connectionType = ConnectionTypeAsynchronously
    }
    
    func feedItems(_ callback: @escaping ([MWFeedItem]) -> Void) {
        self.callback = callback
        items = []
        parser?.parse()
    }
    
    internal func feedParser(_ parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        items.append(item)
    }
    
    internal func feedParserDidFinish(_ parser: MWFeedParser!) {
        if self.items.isEmpty {
            let item = MWFeedItem()
            item.title = "No current service alerts!\nTap to view the service alerts website."
            item.link = "https://www.corvallisoregon.gov/index.aspx?page=1105"
            items.append(item)
        }
        self.callback(self.items)
    }
}
