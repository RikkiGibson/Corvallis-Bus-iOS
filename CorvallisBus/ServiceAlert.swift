//
//  ServiceAlert.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 12/26/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Foundation

struct ServiceAlert {
    var title: String
    var description: String
    var url: String
    var identifier: String
    var isRead: Bool

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    static func fromMWFeedItem(feedItem: MWFeedItem, isRead: Bool) -> ServiceAlert {
        let alert = ServiceAlert(
            title: feedItem.title,
            description: dateFormatter.string(from: feedItem.date),
            url: feedItem.link,
            identifier: feedItem.identifier,
            isRead: isRead)
        
        return alert
    }
}
