//
//  FavoritesViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 6/11/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa

class FavoritesViewController: NSViewController, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setDataSource(self)
        
        NSUserDefaults.groupUserDefaults().favoriteStopIds = [11776, 10308]
        CorvallisBusFavoritesManager.favoriteStops(updateCache: true, fallbackToGrayColor: true, limitResults: false)
                                    .startOnMainThread(onUpdateFavorites)
        // Do view setup here.
    }
    
    var items: [FavoriteStopViewModel] = []
    func onUpdateFavorites(result: Failable<[FavoriteStopViewModel], BusError>) {
        if case .Success(let items) = result {
            self.items = items
        }
        tableView.reloadData()
    }
    
    // MARK - NSTableViewDataSource
    
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return Box(value: items[row])
    }
}
