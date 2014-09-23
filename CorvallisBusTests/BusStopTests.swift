//
//  BusStopTest.swift
//  CorvallisBus
//
//  Created by Rikki Gibson on 9/22/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import Foundation
import XCTest

class BusStopTests : XCTestCase {

    func testBusStopInit() {
        let testJson = ["ID": "123",
            "Name": "Fred",
            "Road": "Main St.",
            "Bearing": "-123.456",
            "AdherancePoint": "false",
            "Lat": "45.76541",
            "Long": "97.55453",
            "Distance": "113.112"]
        
        let stop = BusStop(json: testJson)
//        XCTAssert(stop.ID == 123, "ID")
//        XCTAssert(stop.Name == "Fred", "Name")
//        XCTAssert(stop.Road == "Main St.", "Road")
//        XCTAssert(stop.Bearing == -123.456, "Bearing")
//        XCTAssert(!stop.AdherancePoint, "AdherancePoint")
//        XCTAssert(stop.Lat == 45.76541, "Lat")
//        XCTAssert(stop.Long == 97.55453, "Long")
//        XCTAssert(stop.Distance == 113.112, "Distance")
    }
}