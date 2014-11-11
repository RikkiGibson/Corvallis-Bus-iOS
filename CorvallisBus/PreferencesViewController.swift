//
//  PreferencesViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/8/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

class PreferencesViewController: UIViewController {
    @IBOutlet weak var labelTodayItems: UILabel!
    @IBOutlet weak var stepperTodayItems: UIStepper!
    @IBOutlet weak var counterTodayItems: UITextField!
    @IBOutlet weak var sliderShowNearestStop: UISwitch!
    
    override func viewDidLoad() {
        let processInfo = NSProcessInfo.processInfo()
        let canUseTodayExtension = processInfo.respondsToSelector("operatingSystemVersion") ? processInfo.operatingSystemVersion.majorVersion >= 8 : false
        labelTodayItems.hidden = !canUseTodayExtension
        stepperTodayItems.hidden = !canUseTodayExtension
        counterTodayItems.hidden = !canUseTodayExtension
    }
    override func viewWillAppear(animated: Bool) {
        let todayItemCount = CorvallisBusService.todayViewItemCount
        stepperTodayItems.value = Double(todayItemCount)
        counterTodayItems.text = todayItemCount.description
        
        sliderShowNearestStop.on = CorvallisBusService.shouldShowNearestStop
    }
    
    @IBAction func switchedShouldShowNearestStop(sender: UISwitch) {
        CorvallisBusService.shouldShowNearestStop = sender.on
    }
    
    @IBAction func todayViewItemCountChanged(sender: UIStepper) {
        CorvallisBusService.todayViewItemCount = Int(sender.value)
        counterTodayItems.text = Int(sender.value).description
    }
}