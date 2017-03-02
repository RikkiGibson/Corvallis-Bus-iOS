//
//  FavoritesInterfaceController.swift
//  CorvallisBus
//
//  Created by Christian Mello on 3/1/17.
//  Copyright © 2017 Rikki Gibson. All rights reserved.
//

import WatchKit
import Foundation


class FavoritesInterfaceController: WKInterfaceController {

    @IBOutlet var favoritesTable: WKInterfaceTable!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        favoritesTable.setNumberOfRows(10, withRowType: "FavoritesRow")
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

}
