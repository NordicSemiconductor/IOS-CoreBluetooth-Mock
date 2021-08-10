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

class RetrievingDevicesTest: XCTestCase {
    
    override func setUpWithError() throws {	
        // This method is called AFTER ScannerTableViewController.viewDidLoad()
        // where the BlinkyManager is instantiated. A separate mock manager
        // is not created in this test.
        // Initially mock Bluetooth adapter is powered Off.
        CBMCentralManagerMock.simulatePeripherals([blinky, hrm, thingy])
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }

    override func tearDownWithError() throws {
        // We can't call CBMCentralManagerMock.tearDownSimulation() here.
        // That would invalidate the BlinkyManager in ScannerTableViewController.
        // The central manager must be reused, so let's just power mock off,
        // which will allow us to set different set of peripherals in another test.
        CBMCentralManagerMock.simulatePowerOff()
    }

    func testRetrieval() throws {
        // Devices might have been scanned and cached by some other test.
        // Make sure they're treated as new devices by changing their addresses.
        blinky.simulateMacChange()
        hrm.simulateMacChange()
        
        // Creating a manager with CBMCentralManagerSimpleMockKey = true makes the
        // manager available powered on immediately, without the need to wait 10 ms.
        let manager = CBMCentralManagerFactory.instance(delegate: nil, queue: nil,
                                                        options: [CBMCentralManagerSimpleMockKey : true],
                                                        forceMock: true)
        // Initially, none of the devices was cached.
        let list1 = manager.retrievePeripherals(withIdentifiers: [blinky.identifier, hrm.identifier])
        XCTAssertTrue(list1.isEmpty)
        
        // Simulate a situation when a different app on the iPhone scanned for Blinky
        // which cached the device. This should also work when the device is out of
        // range.
        blinky.simulateCaching()
        
        // Now the Blinky should be available for retrieval.
        let list2 = manager.retrievePeripherals(withIdentifiers: [blinky.identifier, hrm.identifier])
        XCTAssertEqual(list2.count, 1)
        XCTAssert(list2.contains(where: { $0.identifier == blinky.identifier }))
    }
    
    func testRetrievalAfterScanning() throws {
        // Set up the devices in range.
        hrm.simulateProximityChange(.immediate)
        
        let stateUpdated = XCTestExpectation(description: "State Updated")
        let retrieved = XCTestExpectation(description: "Retrieved")
        
        let delegate = CBMCentralManagerDelegateProxy()
        delegate.didUpdateState = { _ in stateUpdated.fulfill() }
        delegate.didDiscoverPeripheral = { manager, _, _, _ in
            // Now it should be available for retrieval.
            let list = manager.retrievePeripherals(withIdentifiers: [hrm.identifier])
            XCTAssertFalse(list.isEmpty)
            
            if !list.isEmpty {
                retrieved.fulfill()
            }
        }
        
        // Creating a manager with CBMCentralManagerSimpleMockKey = true makes the
        // manager available powered on immediately, without the need to wait 10 ms.
        let manager = CBMCentralManagerFactory.instance(delegate: delegate, queue: nil,
                                                        options: [CBMCentralManagerSimpleMockKey : true],
                                                        forceMock: true)
        // Initially, none of the devices was cached.
        let list = manager.retrievePeripherals(withIdentifiers: [hrm.identifier])
        XCTAssertTrue(list.isEmpty)
        
        manager.scanForPeripherals(withServices: nil)
        
        wait(for: [stateUpdated, retrieved], timeout: 1.0)
    }

}
