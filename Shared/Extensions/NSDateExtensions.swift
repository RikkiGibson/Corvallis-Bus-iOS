//
//  NSDateExtensions.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/19/15.
//  Copyright © 2015 Rikki Gibson. All rights reserved.
//

import Foundation

extension Date {
    func isOnSameDay(_ other: Date) -> Bool {
        let calendar = Calendar.current
        let unitFlags: NSCalendar.Unit = [.year, .month, .day]
        let selfComponents = (calendar as NSCalendar).components(unitFlags, from: self)
        let otherComponents = (calendar as NSCalendar).components(unitFlags, from: other)
        
        return selfComponents.day == otherComponents.day &&
            selfComponents.month == otherComponents.month &&
            selfComponents.year == otherComponents.year
    }
    
    func isToday() -> Bool {
        return isOnSameDay(Date())
    }
}
