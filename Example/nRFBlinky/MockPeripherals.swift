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
import CoreBluetoothMock

// MARK: - Mock nRF Blinky

extension CBMUUID {
    static let nordicBlinkyService  = CBMUUID(string: "00001523-1212-EFDE-1523-785FEABCD123")
    static let buttonCharacteristic = CBMUUID(string: "00001524-1212-EFDE-1523-785FEABCD123")
    static let ledCharacteristic    = CBMUUID(string: "00001525-1212-EFDE-1523-785FEABCD123")
}

extension CBMCharacteristicMock {
    
    static let buttonCharacteristic = CBMCharacteristicMock(
        type: .buttonCharacteristic,
        properties: [.notify, .read],
        descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
    )

    static let ledCharacteristic = CBMCharacteristicMock(
        type: .ledCharacteristic,
        properties: [.write, .read]
    )
    
}

extension CBMServiceMock {

    static let blinkyService = CBMServiceMock(
        type: .nordicBlinkyService, primary: true,
        characteristics:
            .buttonCharacteristic,
            .ledCharacteristic
    )
    
}

private class BlinkyCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    private var ledEnabled: Bool = false
    private var buttonPressed: Bool = false
    
    private var ledData: Data {
        return ledEnabled ? Data([0x01]) : Data([0x00])
    }
    
    private var buttonData: Data {
        return buttonPressed ? Data([0x01]) : Data([0x00])
    }

    func reset() {
        ledEnabled = false
        buttonPressed = false
    }

    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristic)
            -> Result<Data, Error> {
        if characteristic.uuid == .ledCharacteristic {
            return .success(ledData)
        } else {
            return .success(buttonData)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristic,
                    data: Data) -> Result<Void, Error> {
        if data.count > 0 {
            ledEnabled = data[0] != 0x00
        }
        return .success(())
    }
}

let blinky = CBMPeripheralSpec
    .simulatePeripheral(proximity: .outOfRange)
    .advertising(
        advertisementData: [
            CBMAdvertisementDataLocalNameKey    : "nRF Blinky",
            CBMAdvertisementDataServiceUUIDsKey : [CBMUUID.nordicBlinkyService],
            CBMAdvertisementDataIsConnectable   : true as NSNumber
        ],
        withInterval: 0.250,
        alsoWhenConnected: false)
    .connectable(
        name: "nRF Blinky",
        services: [.blinkyService],
        delegate: BlinkyCBMPeripheralSpecDelegate(),
        connectionInterval: 0.150,
        mtu: 23)
    .build()

// MARK: - Mock Nordic HRM

extension CBMServiceMock {
    
    static let hrmService = CBMServiceMock(
        type: CBMUUID(string: "180D"), primary: true,
        characteristics:
            CBMCharacteristicMock(
                type: CBMUUID(string: "2A37"), // Heart Rate Measurement
                properties: [.notify],
                descriptors: CBMClientCharacteristicConfigurationDescriptorMock()
            ),
            CBMCharacteristicMock(
                type: CBMUUID(string: "2A38"), // Body Sensor Location
                properties: [.read]
            )
    )
    
}

private struct DummyCBMPeripheralSpecDelegate: CBMPeripheralSpecDelegate {
    // Let's use default implementation.
    // The HRM will not show up in the scan result, as it
    // doesn't advertise with Nordic LED Button service.
    // If you uncomment the line below, and try to connect,
    // connection will fail on "Device not supported" error.
}

let hrm = CBMPeripheralSpec
    .simulatePeripheral(proximity: .outOfRange)
    .advertising(
        advertisementData: [
            CBMAdvertisementDataLocalNameKey : "NordicHRM",
            CBMAdvertisementDataServiceUUIDsKey : [
                CBMUUID(string: "180D"), // Heart Rate
                CBMUUID(string: "180A"), // Device Information
                // BlinkyPeripheral.nordicBlinkyServiceUUID // <- this line
            ],
            CBMAdvertisementDataIsConnectable : true as NSNumber
        ],
        withInterval: 0.100)
    .connectable(
        name: "NordicHRM",
        services: [.hrmService],
        delegate: DummyCBMPeripheralSpecDelegate(),
        connectionInterval: 0.250,
        mtu: 251)
    .build()

// MARK: - Physical Web Beacon

let thingy = CBMPeripheralSpec
    .simulatePeripheral(proximity: .outOfRange)
    .advertising(
        advertisementData: [
            CBMAdvertisementDataServiceUUIDsKey : [
                CBUUID(string: "FEAA")  // Eddystone
            ],
            CBMAdvertisementDataServiceDataKey : [
                // Physical Web beacon: 10ee03676f2e676c2f7049576466972
                // type: URL
                // TX Power: -18 dBm
                // URL: https://goo.gl/pIWdir -> Thingy:52
                CBMUUID(string: "FEAA") : Data(base64Encoded: "EO4DZ28uZ2wvcElXZGaXIA==")
            ]
        ],
        withInterval: 0.100)
    .build()
