/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
@testable import nRF_Blinky
@testable import CoreBluetoothMock

class NormalBehaviorTest: XCTestCase {

    override func setUp() {
        (UIApplication.shared.delegate as! AppDelegate).mockingEnabled = true
        CBMCentralManagerMock.simulatePeripherals([blinky, hrm, thingy])
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }

    override func tearDown() {
        CBMCentralManagerMock.tearDownSimulation()
    }

    func testScanningBlinky() {
        // Set up the devices in range.
        blinky.simulateProximityChange(.immediate)
        hrm.simulateProximityChange(.near)
        thingy.simulateProximityChange(.far)
        // Reset the blinky.
        blinky.simulateReset()

        // Wait until the blinky is found.
        var target: BlinkyPeripheral?
        let found = XCTestExpectation(description: "Device found")
        Sim.onBlinkyDiscovery { blinky in
            XCTAssertEqual(blinky.advertisedName, "nRF Blinky")
            XCTAssert(blinky.isConnectable == true)
            XCTAssert(blinky.isConnected == false)
            XCTAssertGreaterThanOrEqual(blinky.RSSI.intValue, -70 - 15)
            XCTAssertLessThanOrEqual(blinky.RSSI.intValue, -70 + 15)
            target = blinky
            found.fulfill()
        }
        wait(for: [found], timeout: 3)
        XCTAssertNotNil(target)

        // Select found device.
        Sim.post(.selectPeripheral(at: 0))

        // Wait until blinky is connected and ready.
        let connected = XCTestExpectation(description: "Connected")
        let ready = XCTestExpectation(description: "Ready")
        target!.onConnected {
            connected.fulfill()
        }
        target!.onReady { ledSupported, buttonSupported in
            if ledSupported && buttonSupported {
                ready.fulfill()
            }
        }
        wait(for: [connected, ready], timeout: 3)

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navigationController = appDelegate.window!.rootViewController as! UINavigationController
        let blinkyViewController = navigationController.topViewController as! BlinkyViewController

        // Initially, after reset, LED is OFF and button is released.

        // Enable LED by simulating toggling the switch.
        // The `onLedStateDidChange` handler will be called after the initial state has been read.
        let ledEnabled = XCTestExpectation(description: "LED Enabled")
        let ledObserver = target!.onLedStateDidChange { isOn in
            if isOn {
                ledEnabled.fulfill()
            } else {
                // Simulate toggling the switch.
                blinkyViewController.ledToggleSwitch.setOn(true, animated: true)
                blinkyViewController.ledToggleSwitchDidChange(blinkyViewController.ledToggleSwitch)
            }
        }
        wait(for: [ledEnabled], timeout: 6)
        Sim.dispose(ledObserver)

        // Simulate 2 notifications.
        let buttonPressed = XCTestExpectation(description: "Button pressed")
        let buttonReleased = XCTestExpectation(description: "Button released")
        let buttonObserver = target!.onButtonStateDidChange { isPressed in
            if isPressed {
                // Simulate releasing the BTN1 on DK.
                blinky.simulateValueUpdate(Data([0x00]), for: .buttonCharacteristic)
                buttonPressed.fulfill()
            } else {
                buttonReleased.fulfill()
            }
        }
        // Simulate clicking the BTN1 on DK.
        blinky.simulateValueUpdate(Data([0x01]), for: .buttonCharacteristic)
        wait(for: [buttonPressed, buttonReleased], timeout: 1)
        Sim.dispose(buttonObserver)

        // Simulate graceful disconnect.
        let disconnection = XCTestExpectation(description: "Disconnection")
        target!.onDisconnected {
            disconnection.fulfill()
        }
        blinky.simulateDisconnection()
        wait(for: [disconnection], timeout: 1)

        navigationController.popViewController(animated: true)
    }

}
