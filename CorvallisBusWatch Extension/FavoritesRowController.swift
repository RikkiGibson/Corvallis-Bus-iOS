//
//  FavoritesRowController.swift
//  CorvallisBus
//
//  Created by Christian Mello on 3/1/17.
//  Copyright © 2017 Rikki Gibson. All rights reserved.
//

import WatchKit
import Foundation


class FavoritesRowController: WKInterfaceController {

    @IBOutlet var lblStopName: WKInterfaceLabel!
    @IBOutlet var lblRouteName: WKInterfaceLabel!
    @IBOutlet var lblArrivalsSummary: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func update(with model: FavoriteStopViewModel) {
        lblStopName.setText(model.stopName)
        lblRouteName.setText(model.firstRouteName)
        lblRouteName.setText(model.firstRouteArrivals)
    }
}