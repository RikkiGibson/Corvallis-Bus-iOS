//
//  PreferencesViewController.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 11/8/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit

final class PreferencesViewController: UITableViewController {
    @IBOutlet weak var cellShowNearestStop: UITableViewCell!
    @IBOutlet weak var sliderShowNearestStop: UISwitch!
    
    @IBOutlet weak var cellTodayItems: UITableViewCell!
    @IBOutlet weak var stepperTodayItems: UIStepper!
    @IBOutlet weak var counterTodayItems: UITextField!
    override func viewDidLoad() {
        cellShowNearestStop.accessoryView = sliderShowNearestStop
    }
    
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
        cellTodayItems.accessibilityLabel = "Max stops in widget: \(todayItemCount)"
        
        sliderShowNearestStop.isOn = defaults.shouldShowNearestStop
    }
    
    @IBAction func switchedShouldShowNearestStop(_ sender: UISwitch) {
        let defaults = UserDefaults.groupUserDefaults()
        defaults.shouldShowNearestStop = sender.isOn
    }
    
    @IBAction func todayViewItemCountChanged(_ sender: UIStepper) {
        let intValue = Int(sender.value)
        let defaults = UserDefaults.groupUserDefaults()
        defaults.todayViewItemCount = intValue
        counterTodayItems.text = intValue.description
        cellTodayItems.accessibilityLabel = "Max stops in widget: \(intValue)"
        stepperTodayItems.accessibilityValue = intValue.description
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
