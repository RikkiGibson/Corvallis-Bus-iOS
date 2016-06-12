//
//  FavoritesTableCellView.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 6/11/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa

class FavoritesTableCellView: NSTableCellView {
    override func viewDidMoveToWindow() {
        labelFirstRouteName.wantsLayer = true
        labelFirstRouteName.layer!.cornerRadius = 6
        
        labelSecondRouteName.wantsLayer = true
        labelSecondRouteName.layer!.cornerRadius = 6
    }
    
    @IBOutlet weak var labelStopName: NSTextField!
    @IBOutlet weak var labelFirstRouteName: NSTextField!
    @IBOutlet weak var labelFirstRouteArrivals: NSTextField!
    @IBOutlet weak var labelSecondRouteName: NSTextField!
    @IBOutlet weak var labelSecondRouteArrivals: NSTextField!
    @IBOutlet weak var labelDistanceFromUser: NSTextField!
    
    override var objectValue: AnyObject? {
        set {
            if let box = newValue as? Box<FavoriteStopViewModel> {
                populateView(box.value)
            } else {
                Swift.print("nil was assigned to FavoritesTableCellView.objectValue")
            }
        }
        get {
            return nil
        }
    }
    
    func populateView(model: FavoriteStopViewModel) {
        labelStopName.stringValue = model.stopName
        labelFirstRouteName.stringValue = model.firstRouteName
        labelFirstRouteName.backgroundColor = model.firstRouteColor
        labelFirstRouteArrivals.stringValue = model.firstRouteArrivals
        
        labelSecondRouteName.stringValue = model.secondRouteName
        labelSecondRouteName.backgroundColor = model.secondRouteColor
        labelSecondRouteArrivals.stringValue = model.secondRouteArrivals
        
        labelDistanceFromUser.stringValue = model.distanceFromUser
    }
}
