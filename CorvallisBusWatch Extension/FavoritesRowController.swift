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
        
        lblArrivalsSummary.setText(model.firstRouteArrivals)
    }
    
    func concatStopName(stopName:String)->String {
        var stopString = stopName
        let replaceDirs = ["NW ","NE ","SW ","SE "]
        let replaceAbrvs = [" St"," Dr"," Ave"]
        
        for string in replaceDirs {
            stopString = stopString.replacingOccurrences(of:string, with: "", options: .literal)
        }
        
        for string in replaceAbrvs {
            stopString = stopString.replacingOccurrences(of:string, with: "", options: .literal)
        }
        
        return stopString
    }
}
