//
//  FavoritesRowController.swift
//  CorvallisBus
//
//  Created by Christian Mello on 3/1/17.
//  Copyright © 2017 Rikki Gibson. All rights reserved.
//

import WatchKit

class FavoritesRowController: NSObject {

    @IBOutlet var lblStopName: WKInterfaceLabel!
    
    @IBOutlet var groupRouteName: WKInterfaceGroup!
    @IBOutlet var lblRouteName: WKInterfaceLabel!
    
    @IBOutlet var lblArrivalsSummary: WKInterfaceLabel!
    @IBOutlet var separatorColor: WKInterfaceSeparator!
        
    func update(with model: FavoriteStopViewModel) {
        let longStopName = model.stopName
        let shortStopName = concatStopName(stopName:longStopName)
        lblStopName.setText(shortStopName)
        
        lblRouteName.setText(model.firstRouteName)
        groupRouteName.setBackgroundColor(model.firstRouteColor)
        separatorColor.setColor(model.firstRouteColor)
        
        let longTime = model.firstRouteArrivals
        let shortTime = concatTime(time: longTime)
        lblArrivalsSummary.setText(shortTime)
    }
    
    func concatStopName(stopName:String)->String {
        var stopString = stopName
        let replaceDirs = ["NW ","NE ","SW ","SE "]
        let replaceAbrvs = [" St"," Dr"," Ave"]
        
        for string in replaceDirs {
            stopString = stopString.replacingOccurrences(of: string, with: "", options: .literal)
        }
        
        for string in replaceAbrvs {
            stopString = stopString.replacingOccurrences(of: string, with: "", options: .literal)
        }
        
        return stopString
    }
    
    func concatTime(time:String)->String {
        var timeString = time
        let replaceTimes = ["hours":"hrs","hour":"hr","minutes":"mins","minute":"min","seconds":"secs","second":"sec"," AM":""," PM":""]
        
        for (long,short) in replaceTimes {
            timeString = timeString.replacingOccurrences(of: long, with: short, options: .literal)
        }
        
        return timeString
    }
}
