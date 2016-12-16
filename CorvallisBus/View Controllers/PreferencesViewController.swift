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
        if #available(iOS 10, *) {
            stepperTodayItems.minimumValue = 2
        } else {
            stepperTodayItems.minimumValue = 1
        }
        stepperTodayItems.maximumValue = 7
        
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? BusWebViewController ??
            segue.destinationViewController.childViewControllers.first as? BusWebViewController
        {
            destination.initialURL = segue.identifier == "PrivacyPolicyWebSegue"
                ? NSURL(string: "https://rikkigibson.github.io/corvallisbus/privacy/index.html")!
                : NSURL(string: "https://rikkigibson.github.io/corvallisbus/index.html")!
            destination.alwaysShowNavigationBar = true
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) { }
    
}
