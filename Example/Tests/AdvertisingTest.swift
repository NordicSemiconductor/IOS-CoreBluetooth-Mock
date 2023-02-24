/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// This test checks different advertising configurations.
class AdvertisingTest: XCTestCase {
    
    override func setUpWithError() throws {
        // This method is called AFTER ScannerTableViewController.viewDidLoad()
        // where the BlinkyManager is instantiated. A separate mock manager
        // is not created in this test.
        // Initially mock Bluetooth adapter is powered Off.
        CBMCentralManagerMock.simulatePeripherals([thingy])
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }

    override func tearDownWithError() throws {
        // We can't call CBMCentralManagerMock.tearDownSimulation() here.
        // That would invalidate the BlinkyManager in ScannerTableViewController.
        // The central manager must be reused, so let's just power mock off,
        // which will allow us to set different set of peripherals in another test.
        CBMCentralManagerMock.simulatePowerOff()
    }
    
    func testNoAdvertising() throws {
        thingy.simulateProximityChange(.outOfRange)
        
        let managerPoweredOn = XCTestExpectation(description: "Powered On")
        let found = XCTestExpectation(description: "Device not found")
        found.isInverted = true
        
        // Define the CBCentralManagerDelegate, which will wait until the manager is ready.
        let delegate = CBMCentralManagerDelegateProxy()
        delegate.didUpdateState = { _ in managerPoweredOn.fulfill() }
        delegate.didDiscoverPeripheral = { _, _, _, _ in found.fulfill() }
        
        // Create an instance of mock CBMCentralManager.
        let manager = CBMCentralManagerMock(delegate: delegate, queue: nil)
        manager.scanForPeripherals(withServices: nil)
        
        // Wait until the manager is initialized.
        wait(for: [managerPoweredOn], timeout: 1.0)
        wait(for: [found], timeout: 2.0)
    }
    
    func testAdvertising() throws {
        thingy.simulateProximityChange(.immediate)
        
        let managerPoweredOn = XCTestExpectation(description: "Powered On")
        // Physical web starts advertising immediately.
        let pwFound = XCTestExpectation(description: "Physical Web found")
        // Thingy:52 starts advertising with 2 second delay.
        var thingyNotFound: XCTestExpectation? = XCTestExpectation(description: "Thingy:52 not found")
        thingyNotFound!.isInverted = true
        let thingyFound = XCTestExpectation(description: "Thingy:52 found")
        
        // Define the CBCentralManagerDelegate, which will wait until the manager is ready.
        let delegate = CBMCentralManagerDelegateProxy()
        delegate.didUpdateState = { _ in managerPoweredOn.fulfill() }
        delegate.didDiscoverPeripheral = { _, peripheral, advertisementData, _ in
            let name = advertisementData[CBMAdvertisementDataLocalNameKey] as? String
            if name == nil {
                pwFound.fulfill()
            } else {
                thingyNotFound?.fulfill()
                thingyFound.fulfill()
            }
        }
        
        // Create an instance of mock CBMCentralManager.
        let manager = CBMCentralManagerMock(delegate: delegate, queue: nil)
        
        // Wait until the manager is initialized.
        wait(for: [managerPoweredOn], timeout: 0.5)
        
        // Start scanning and check results.
        manager.scanForPeripherals(withServices: [],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        wait(for: [pwFound], timeout: 0.6)
        wait(for: [thingyNotFound!], timeout: 1.0)
        thingyNotFound = nil
        wait(for: [thingyFound], timeout: 4.0)
    }
    
    func testAdvertisingNoDuplicates() throws {
        var count = 0
        
        thingy.simulateProximityChange(.immediate)
        
        let managerPoweredOn = XCTestExpectation(description: "Powered On")
        var pwFound = XCTestExpectation(description: "Physical Web found")
        var pwFoundMultipleTimes = XCTestExpectation(description: "Physical Web found multiple times")
        pwFoundMultipleTimes.isInverted = true
        
        // Define the CBCentralManagerDelegate, which will wait until the manager is ready.
        let delegate = CBMCentralManagerDelegateProxy()
        delegate.didUpdateState = { _ in managerPoweredOn.fulfill() }
        delegate.didDiscoverPeripheral = { _, peripheral, advertisementData, _ in
            switch count {
            case 0: pwFound.fulfill()
            default: pwFoundMultipleTimes.fulfill()
            }
            count += 1
        }
        
        // Create an instance of mock CBMCentralManager.
        let manager = CBMCentralManagerMock(delegate: delegate, queue: nil)
        
        // Wait until the manager is initialized.
        wait(for: [managerPoweredOn], timeout: 0.5)
        
        // Start scanning and check results.
        manager.scanForPeripherals(withServices: [CBMUUID(string: "FEAA")])
        wait(for: [pwFound, pwFoundMultipleTimes], timeout: 1.5)
        
        // Restart scanning.
        manager.stopScan()
        
        // The same conditions should again be met after scanning was restarted.
        pwFound = XCTestExpectation(description: "Physical Web found")
        pwFoundMultipleTimes = XCTestExpectation(description: "Physical Web found multiple times")
        pwFoundMultipleTimes.isInverted = true
        
        count = 0
        
        manager.scanForPeripherals(withServices: [
            CBMUUID(string: "FEAA"), CBMUUID(string: "FEAB")
        ])
        wait(for: [pwFound, pwFoundMultipleTimes], timeout: 1.5)
    }
    
}
