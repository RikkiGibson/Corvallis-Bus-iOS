//
//  CorvallisBusTests.swift
//  CorvallisBusTests
//
//  Created by Rikki Gibson on 9/21/14.
//  Copyright (c) 2014 Rikki Gibson. All rights reserved.
//

import UIKit
import XCTest

class CorvallisBusTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDateFromString() {
        var date: NSDate?
        date <<< (value: "09 Oct 14 18:23 -0700", format: "dd MMM yy HH:mm ZZZ")
        println(date?.description)
    }
    
}
