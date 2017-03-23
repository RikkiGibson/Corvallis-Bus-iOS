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
    
    @IBAction func mnubtnRefresh() {
        print("HELP")
    }
    
    var favoriteStops: [FavoriteStopViewModel] = []
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        favoriteStops = CorvallisBusFavoritesManager.cachedFavoriteStopsForWidget()
        favoritesTable.setNumberOfRows(favoriteStops.count, withRowType: "FavoritesRow")
        
        for i in 0..<favoritesTable.numberOfRows {
            guard let controller = favoritesTable.rowController(at: i) as? FavoritesRowController else { continue }
            controller.update(with: favoriteStops[i])
        }

        // This will force the back-end to actually fetch some favorite stops.
        UserDefaults.groupUserDefaults().favoriteStopIds = [14704, 10308]
        
        // Configure interface objects here.
        CorvallisBusFavoritesManager.favoriteStopsForWidget()
            .startOnMainThread(onStopsLoaded)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        // Simulator crashes when selecting a row. why?
        print(favoriteStops[rowIndex].stopId)
    }
    
    func onStopsLoaded(failable:Failable<[FavoriteStopViewModel], BusError>) {
        guard case .success(let models) = failable else {
            print("ERROR")
            return
        }
        favoriteStops = models
        
        // can't set number of rows in here. why?
        //favoritesTable.setNumberOfRows(favoriteStops.count, withRowType: "FavoritesRow")
        for i in 0..<favoritesTable.numberOfRows {
            guard let controller = favoritesTable.rowController(at: i) as? FavoritesRowController else { continue }
            controller.update(with: favoriteStops[i])
        }
    }

}
