//
//  PreferencesViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/8/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class PreferencesViewController: UITableViewController {
    @IBOutlet weak var stepperTodayItems: UIStepper!
    @IBOutlet weak var counterTodayItems: UITextField!
    @IBOutlet weak var sliderShowNearestStop: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 10, *) {
            stepperTodayItems.minimumValue = 2
        } else {
            stepperTodayItems.minimumValue = 1
        }
        stepperTodayItems.maximumValue = 7
        
        let defaults = UserDefaults.groupUserDefaults()
        
        let todayItemCount = defaults.todayViewItemCount
        stepperTodayItems.value = Double(todayItemCount)
        counterTodayItems.text = todayItemCount.description
        
        sliderShowNearestStop.isOn = defaults.shouldShowNearestStop
    }
    
    @IBAction func switchedShouldShowNearestStop(_ sender: UISwitch) {
        let defaults = UserDefaults.groupUserDefaults()
        defaults.shouldShowNearestStop = sender.isOn
    }
    
    @IBAction func todayViewItemCountChanged(_ sender: UIStepper) {
        let defaults = UserDefaults.groupUserDefaults()
        defaults.todayViewItemCount = Int(sender.value)
        counterTodayItems.text = Int(sender.value).description
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            return
        }
        
        switch indexPath.row {
        case 0:
            presentURL(URL(string: "https://rikkigibson.github.io/corvallisbus/ios-user-guide/index.html")!)
        case 1:
            presentURL(URL(string: "https://rikkigibson.github.io/corvallisbus/index.html")!)
        case 2:
            presentURL(URL(string: "https://rikkigibson.github.io/corvallisbus/privacy/index.html")!)
        default:
            break
        }
    }
}
