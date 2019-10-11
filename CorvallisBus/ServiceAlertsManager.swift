//
//  ServiceAlertsManager.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/26/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import MapKit

final class ServiceAlertsManager {
    func serviceAlerts() -> Promise<[ServiceAlertViewModel], BusError> {
        return CorvallisBusAPIClient.serviceAlerts()
            .map({ (alertsJSON: [[String: AnyObject]]) -> [ServiceAlertViewModel] in
                return alertsJSON.compactMap({ ServiceAlert.fromDictionary($0) })
                    .map({
                        let defaults = UserDefaults.groupUserDefaults()
                        let seenIds = defaults.seenServiceAlertIds
                        
                        return ServiceAlertViewModel.fromServiceAlert(serviceAlert: $0, isRead: seenIds.contains($0.id))
                    })
            })
    }
    
    func toggleRead(_ alert: ServiceAlertViewModel) -> ServiceAlertViewModel {
        let defaults = UserDefaults.groupUserDefaults()
        var seenIdentifiers = defaults.seenServiceAlertIds
        if alert.isRead {
            seenIdentifiers.remove(alert.id)
        } else {
            seenIdentifiers.insert(alert.id)
        }
        
        defaults.seenServiceAlertIds = seenIdentifiers
        var newAlert = alert
        newAlert.isRead = !newAlert.isRead
        return newAlert
    }
    
    func markRead(_ alert: ServiceAlertViewModel) -> ServiceAlertViewModel {
        if alert.isRead {
            return alert
        }
        
        let defaults = UserDefaults.groupUserDefaults()
        var seenIdentifiers = defaults.seenServiceAlertIds
        seenIdentifiers.insert(alert.id)
        defaults.seenServiceAlertIds = seenIdentifiers
        
        var newAlert = alert
        newAlert.isRead = true
        return newAlert
    }
}
