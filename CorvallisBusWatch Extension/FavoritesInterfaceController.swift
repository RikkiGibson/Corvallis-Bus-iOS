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
        let cachedFavorites = CorvallisBusFavoritesManager.cachedFavoriteStopsForWidget()
        favoritesTable.setNumberOfRows(cachedFavorites.count, withRowType: "FavoritesRow")
        
        for i in 0..<favoritesTable.numberOfRows {
            guard let controller = favoritesTable.rowController(at: i) as? FavoritesRowController else { continue }
            controller.update(with: cachedFavorites[i])
        }
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
    
    func onStopsLoaded(failable:Failable<[FavoriteStopViewModel], BusError>) {
        guard case .success(let models) = failable else {
            print("ERROR")
            return
        }
        for i in 0..<favoritesTable.numberOfRows {
            print(i)
            guard let controller = favoritesTable.rowController(at: i) as? FavoritesRowController else { continue }
            controller.update(with: models[i])
        }
    }

}
