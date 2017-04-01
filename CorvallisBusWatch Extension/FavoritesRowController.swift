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
        lblStopName.setText(model.stopName)
        
        lblRouteName.setText(model.firstRouteName)
        groupRouteName.setBackgroundColor(model.firstRouteColor)
        separatorColor.setColor(model.firstRouteColor)
        
        lblArrivalsSummary.setText(model.firstRouteArrivals)
    }
}
