//
//  ServiceAlertsFeedParserDelegate.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/26/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

internal class ServiceAlertsFeedParserDelegate : NSObject, MWFeedParserDelegate {
    private let parser = MWFeedParser(feedURL: NSURL(string: "http://www.corvallisoregon.gov/Rss.aspx?type=5&cat=100,104,105,106,107,108,109,110,111,112,113,114,58,119&dept=12&paramtime=Current")!)
    
    private var items = [MWFeedItem]()
    private var callback: [MWFeedItem] -> Void = { items in }
    
    override init() {
        super.init()
        
        self.parser.delegate = self
        self.parser.feedParseType = ParseTypeItemsOnly
        self.parser.connectionType = ConnectionTypeAsynchronously
    }
    
    func feedItems(callback: [MWFeedItem] -> Void) {
        self.callback = callback
        self.items = [MWFeedItem]()
        self.parser.parse()
    }
    
    internal func feedParser(parser: MWFeedParser!, didParseFeedItem item: MWFeedItem!) {
        items.append(item)
    }
    
    internal func feedParserDidFinish(parser: MWFeedParser!) {
        if self.items.count == 0 {
            let item = MWFeedItem()
            item.title = "No current service alerts!\nTap to view the service alerts website."
            item.link = "http://www.corvallisoregon.gov/index.aspx?page=1105"
            items.append(item)
        }
        self.callback(self.items)
    }
}