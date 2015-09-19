//
//  NSDateExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/19/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension NSDate {
    func isOnSameDay(other: NSDate) -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags: NSCalendarUnit = [.NSYearCalendarUnit, .NSMonthCalendarUnit, .NSDayCalendarUnit]
        let selfComponents = calendar.components(unitFlags, fromDate: self)
        let otherComponents = calendar.components(unitFlags, fromDate: other)
        
        return selfComponents.day == otherComponents.day &&
            selfComponents.month == otherComponents.month &&
            selfComponents.year == otherComponents.year
    }
    
    func isToday() -> Bool {
        return isOnSameDay(NSDate())
    }
}