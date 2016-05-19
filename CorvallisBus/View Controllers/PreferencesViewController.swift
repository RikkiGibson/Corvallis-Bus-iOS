//
//  PreferencesViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/8/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class PreferencesViewController: UIViewController {
    @IBOutlet weak var labelTodayItems: UILabel!
    @IBOutlet weak var stepperTodayItems: UIStepper!
    @IBOutlet weak var counterTodayItems: UITextField!
    @IBOutlet weak var sliderShowNearestStop: UISwitch!
    
    override func viewWillAppear(animated: Bool) {
        let defaults = NSUserDefaults.groupUserDefaults()
        
        let todayItemCount = defaults.todayViewItemCount
        stepperTodayItems.value = Double(todayItemCount)
        counterTodayItems.text = todayItemCount.description
        
        sliderShowNearestStop.on = defaults.shouldShowNearestStop
    }
    
    @IBAction func switchedShouldShowNearestStop(sender: UISwitch) {
        let defaults = NSUserDefaults.groupUserDefaults()
        defaults.shouldShowNearestStop = sender.on
    }
    
    @IBAction func todayViewItemCountChanged(sender: UIStepper) {
        let defaults = NSUserDefaults.groupUserDefaults()
        defaults.todayViewItemCount = Int(sender.value)
        counterTodayItems.text = Int(sender.value).description
    }
    
    @IBAction func tutorialButtonTouched() {
        presentTutorial()
    }
}
