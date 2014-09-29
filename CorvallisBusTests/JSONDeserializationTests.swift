//
//  BusStopTest.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import XCTest

class JSONDeserializationTests : XCTestCase {

    func testBusStop() {
        let testJson: [String: AnyObject] =
           ["ID": 123,
            "Name": "Fred",
            "Road": "Main St.",
            "Bearing": -123.456,
            "AdherancePoint": false,
            "Lat": 45.76541,
            "Long": 97.55453]
        
        let actual = BusStop(data: testJson)
        let expected = BusStop()
        expected.ID = 123
        expected.Name = "Fred"
        expected.Road = "Main St."
        expected.Bearing = -123.456
        expected.AdherancePoint = false
        expected.Lat = 45.76541
        expected.Long = 97.55453
        
        XCTAssert(actual == expected)
    }
    
    func testBusRoute() {
        let testJson: [String: AnyObject] =
            ["Name":"1",
             "AdditionalName":"Joe",
             "Description":"Hello",
             "URL":"http://something.com",
             "Path":"down by the river"]
        
        let actual = BusRoute(data: testJson)
        let expected = BusRoute()
        
    }
}