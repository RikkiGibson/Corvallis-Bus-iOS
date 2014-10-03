//
//  BusArrival.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 10/2/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation

class BusArrival : Deserializable {
    var expected: NSDate?
    var route: String?
    var scheduled: NSDate?
    
    required init(data: [String : AnyObject]) {
        self.expected <<< data["Expected"]
        self.route <<< data["Route"]
        self.scheduled <<< data["Scheduled"]
    }
}