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

class MultipleInstancesTest: XCTestCase {

    override func setUpWithError() throws {
        // This method is called AFTER ScannerTableViewController.viewDidLoad()
        // where the BlinkyManager is instantiated. A separate mock manager
        // is not created in this test.
        // Initially mock Bluetooth adapter is powered Off.
        CBMCentralManagerMock.simulatePeripherals([powerPack])
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
    }

    override func tearDownWithError() throws {
        // We can't call CBMCentralManagerMock.tearDownSimulation() here.
        // That would invalidate the BlinkyManager in ScannerTableViewController.
        // The central manager must be reused, so let's just power mock off,
        // which will allow us to set different set of peripherals in another test.
        CBMCentralManagerMock.simulatePowerOff()
    }

    func testMultipleServiceInstances() throws {
        // Devices might have been scanned and cached by some other test.
        // Make sure they're treated as new devices by changing their addresses.
        powerPack.simulateProximityChange(.immediate)
        
        let managerPoweredOn = XCTestExpectation(description: "Powered On")
        let powerPackFound = XCTestExpectation(description: "Found")
        let otherFound = XCTestExpectation(description: "Other found")
        otherFound.isInverted = true
        let twoBatteryServicesFound = XCTestExpectation(description: "Battery Services found")
        let primaryBatteryLevelCorrect = XCTestExpectation(description: "Primary Battery at 75%")
        let secondaryBatteryLevelCorrect = XCTestExpectation(description: "Secondary Battery at 100%")
        
        // Create an instance of a mock CBMCentralManager.
        let manager = CBMCentralManagerMock()
        
        // Define the CBMPeripheralDelegate, which will wait until the services are
        // discovered and will discover characteristics.
        let peripheralDelegate = CBMPeripheralDelegateProxy()
        peripheralDelegate.didDiscoverServices = { peripheral, error in
            XCTAssertNil(error)
            
            powerPackFound.fulfill()
            
            if let services = peripheral.services, services.count == 2 {
                twoBatteryServicesFound.fulfill()
                
                services.forEach { batteryService in
                    peripheral.discoverCharacteristics([.batteryLevelCharacteristic], for: batteryService)
                }
            }
        }
        peripheralDelegate.didDiscoverCharacteristics = { peripheral, service, error in
            XCTAssertNil(error)
            
            XCTAssertNotNil(service.characteristics)
            XCTAssert(service.characteristics?.count == 1)
            
            if let batteryLevel = service.characteristics?.first {
                peripheral.discoverDescriptors(for: batteryLevel)
            }
        }
        peripheralDelegate.didDiscoverDescriptors = { peripheral, characteristic, error in
            XCTAssertNil(error)
            
            XCTAssertNotNil(characteristic.descriptors)
            XCTAssert(characteristic.descriptors?.count == 1)
            
            if let userDescription = characteristic.descriptors?.first {
                peripheral.readValue(for: userDescription)
            }
        }
        peripheralDelegate.didUpdateDescriptorValue = { peripheral, descriptor, error in
            XCTAssertNil(error)
            
            if let parent = descriptor.optionalCharacteristic {
                peripheral.readValue(for: parent)
            }
        }
        peripheralDelegate.didUpdateCharacteristicValue = { peripheral, characteristic, error in
            XCTAssertNil(error)
            
            if let userDescription = characteristic.descriptors?.first,
               let value = userDescription.value as? Data,
               let description = String(data: value, encoding: .utf8) {
                switch description {
                case "Primary":
                    XCTAssertNotNil(characteristic.value)
                    XCTAssert(characteristic.value?.count == 1)
                    XCTAssert(characteristic.value?[0] == 75)
                    
                    if characteristic.value?[0] == 75 {
                        primaryBatteryLevelCorrect.fulfill()
                    }
                case "Secondary":
                    XCTAssertNotNil(characteristic.value)
                    XCTAssert(characteristic.value?.count == 1)
                    XCTAssert(characteristic.value?[0] == 100)
                    
                    if characteristic.value?[0] == 100 {
                        secondaryBatteryLevelCorrect.fulfill()
                    }
                default:
                    XCTFail()
                }
            } else {
                XCTFail("Characteristic User Description Descriptor not found")
            }
        }
        
        // Define the CBCentralManagerDelegate, which will wait until the manager is ready
        // and will check the successful retrieval.
        let delegate = CBMCentralManagerDelegateProxy()
        delegate.didUpdateState = { _ in managerPoweredOn.fulfill() }
        delegate.didDiscoverPeripheral = { manager, peripheral, _, _ in
            guard peripheral.identifier == powerPack.identifier else {
                otherFound.fulfill()
                return
            }
            powerPackFound.fulfill()
            
            // Connect to the device when found.
            peripheral.delegate = peripheralDelegate
            manager.connect(peripheral)
        }
        delegate.didConnect = { manager, peripheral in
            // Discover services.
            peripheral.discoverServices([.batteryService])
        }
        manager.delegate = delegate
        
        // Wait until the manager is initialized.
        wait(for: [managerPoweredOn], timeout: 1.0)
        
        // Scan only for HRM device. Other devices may also be in range.
        manager.scanForPeripherals(withServices: [.batteryService])
        
        wait(for: [
                powerPackFound, otherFound,
                twoBatteryServicesFound,
                primaryBatteryLevelCorrect,
                secondaryBatteryLevelCorrect
             ],
             timeout: 3.0)
    }

}
