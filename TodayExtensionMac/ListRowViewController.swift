//
//  ListRowViewController.swift
//  TodayExtensionMac
//
//  Created by Rikki Gibson on 6/12/16.
//  Copyright © 2016 Rikki Gibson. All rights reserved.
//

import Cocoa

class ListRowViewController: NSViewController {

    @IBOutlet weak var labelStopName: NSTextField!
    
    @IBOutlet weak var labelFirstRouteName: NSTextField!
    @IBOutlet weak var labelFirstRouteArrivals: NSTextField!
    
    @IBOutlet weak var labelSecondRouteName: NSTextField!
    @IBOutlet weak var labelSecondRouteArrivals: NSTextField!
    
    @IBOutlet weak var labelDistanceFromUser: NSTextField!
    
    override var nibName: String? {
        return "ListRowViewController"
    }

    override func loadView() {
        super.loadView()
        view.setFrameSize(NSSize(width: 0, height: 80))
        preferredContentSize = view.frame.size
        labelFirstRouteName.wantsLayer = true
        labelFirstRouteName.layer!.cornerRadius = 6
        
        labelSecondRouteName.wantsLayer = true
        labelSecondRouteName.layer!.cornerRadius = 6
        
        guard let box = representedObject as? Box<FavoriteStopViewModel> else {
            return
        }
        
        let model = box.value
        
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
