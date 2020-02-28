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

import Foundation
import CoreBluetooth
import CoreBluetoothMock

// MARK: - Mock nRF Blinky

let buttonCharacteristic = CBCharacteristicMock(
    type: BlinkyPeripheral.buttonCharacteristicUUID,
    properties: [.notify, .read],
    descriptors: CBClientCharacteristicConfigurationDescriptorMock()
)

let ledCharacteristic = CBCharacteristicMock(
    type: BlinkyPeripheral.ledCharacteristicUUID,
    properties: [.write, .read]
)

private let blinkySerivce = CBServiceMock(
    type: BlinkyPeripheral.nordicBlinkyServiceUUID, primary: true,
    characteristics:
        buttonCharacteristic,
        ledCharacteristic
)

private class BlinkyMockPeripheralDelegate: MockPeripheralDelegate {
    private var ledState: Bool = false
    private var buttonState: Bool = false
    
    private var ledData: Data {
        return ledState ? Data([0x01]) : Data([0x00])
    }
    
    private var buttonData: Data {
        return buttonState ? Data([0x01]) : Data([0x00])
    }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveReadRequestFor characteristic: CBCharacteristicType)
        -> Result<Data, Error> {
            if characteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
                return .success(ledData)
            } else {
                return .success(buttonData)
            }
    }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteRequestFor characteristic: CBCharacteristicType,
                    data: Data) -> Result<Void, Error> {
        if data.count > 0 {
            ledState = data[0] != 0x00
        }
        // Let's simulate a button press every time LED was enabled
        if ledState {
            buttonState = !buttonState
            peripheral.simulateValueUpdate(buttonData, for: buttonCharacteristic)
        }
        return .success(())
    }
}

let blinky = MockPeripheral
    .simulatePeripheral(proximity: .immediate)
    .advertising(
        advertisementData: [
            CBAdvertisementDataLocalNameKey : "nRF Blinky",
            CBAdvertisementDataServiceUUIDsKey : [BlinkyPeripheral.nordicBlinkyServiceUUID],
            CBAdvertisementDataIsConnectable : true as NSNumber
        ],
        withInterval: 0.250,
        alsoWhenConnected: false)
    .connectable(
        name: "nRF Blinky",
        services: [blinkySerivce],
        delegate: BlinkyMockPeripheralDelegate(),
        connectionInterval: 0.150,
        mtu: 23)
    .build()

// MARK: - Mock Nordic HRM

private let hrmSerivce = CBServiceMock(
    type: CBUUID(string: "180D"), primary: true,
    characteristics:
        CBCharacteristicMock(
            type: CBUUID(string: "2A37"), // Heart Rate Measurement
            properties: [.notify],
            descriptors: CBClientCharacteristicConfigurationDescriptorMock()
        ),
        CBCharacteristicMock(
            type: CBUUID(string: "2A38"), // Body Sensor Location
            properties: [.read]
        )
)

private struct DummyMockPeripheralDelegate: MockPeripheralDelegate {
    // Let's use default implementation.
    // The HRM will not show up in the scan result, as it
    // doesn't advertise with Nordic LED Button service.
    // If you uncomment the line below, and try to connect,
    // connection will fail on "Device not supported" error.
}

let hrm = MockPeripheral
    .simulatePeripheral(proximity: .far)
    .advertising(
        advertisementData: [
            CBAdvertisementDataLocalNameKey : "NordicHRM",
            CBAdvertisementDataServiceUUIDsKey : [
                CBUUID(string: "180D"), // Heart Rate
                CBUUID(string: "180A"), // Device Information
                // BlinkyPeripheral.nordicBlinkyServiceUUID // <- this line
            ],
            CBAdvertisementDataIsConnectable : true as NSNumber
        ],
        withInterval: 0.100)
    .connectable(
        name: "NordicHRM",
        services: [hrmSerivce],
        delegate: DummyMockPeripheralDelegate(),
        connectionInterval: 0.250,
        mtu: 251)
    .build()

// MARK: - Physical Web Beacon

let thingy = MockPeripheral
    .simulatePeripheral()
    .advertising(
        advertisementData: [
            CBAdvertisementDataServiceUUIDsKey : [
                CBUUID(string: "FEAA")  // Eddystone
            ],
            CBAdvertisementDataServiceDataKey : [
                // Physical Web beacon: 10ee03676f2e676c2f7049576466972
                // type: URL
                // TX Power: -18 dBm
                // URL: https://goo.gl/pIWdir -> Thingy:52
                CBUUID(string: "FEAA") : Data(base64Encoded: "EO4DZ28uZ2wvcElXZGaXIA==")
            ]
        ],
        withInterval: 2.500)
    .build()
