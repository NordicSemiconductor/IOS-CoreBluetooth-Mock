//
//  nRFBlinky_UITests.swift
//  nRFBlinky_UITests
//
//  Created by Aleksander Nowakowski on 02/03/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest

class nRFBlinky_UITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Start scanning
        let scanner = app.tables["Scan results"]
        XCTAssert(scanner.cells["nRF Blinky"].waitForExistence(timeout: 2.0))
        
        // Wait for device to appear and tap it.
        XCTAssertEqual(scanner.cells.count, 1)
        scanner.cells["nRF Blinky"].tap()
        
        let control = app.tables["Control"]
        let ledState = control.staticTexts["ledState"]
        let buttonState = control.staticTexts["buttonState"]
        let ledSwitch = control.switches["ledSwitch"]
        XCTAssertEqual(ledState.label, "UNKNOWN")
        XCTAssertEqual(buttonState.label, "UNKNOWN")
        
        // Wait for the device to connect.
        sleep(1)
        XCTAssertEqual(ledState.label, "OFF")
        XCTAssertEqual(buttonState.label, "RELEASED")
        XCTAssert(ledSwitch.isOn == false)
        
        // Tap LED switch to turn the LED on.
        ledSwitch.tap()
        XCTAssert(ledSwitch.isOn == true)
        XCTAssertEqual(ledState.label, "ON")
        
        // A button notification should also be received at this time.
        XCTAssertEqual(buttonState.label, "PRESSED")
        
        // Tap the LED switch again to disable it.
        ledSwitch.tap()
        XCTAssert(ledSwitch.isOn == false)
        XCTAssertEqual(ledState.label, "OFF")
        
        // Navigating back and disconnecting.
        app.buttons["Scanner"].tap()
        XCTAssertEqual(scanner.cells.count, 0)
        
        // nRF Blinky should start advertising quickly.
        XCTAssert(scanner.cells["nRF Blinky"].waitForExistence(timeout: 2.0))
        XCTAssertEqual(scanner.cells.count, 1)
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}

private extension XCUIElement {
    
    var isOn: Bool {
        if let value = value as? String {
            return value == "1"
        }
        return false
    }
}
