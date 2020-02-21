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

class BlinkyCentralManagerMock: CBCentralManagerMockDelegate {
    private let blinkyId = UUID()
    
    func centralManager(_ central: CBCentralManagerMock,
                        didStartScanningForPeripheralsWithServices serviceUUIDs: [CBUUID]?)
        -> [AdvertisingPeripheral] {
            
        let blinky = AdvertisingPeripheral(identifier: blinkyId,
                                advertisementData: [
                                    CBAdvertisementDataLocalNameKey : "nRF Blinky",
                                    CBAdvertisementDataServiceUUIDsKey : [BlinkyPeripheral.nordicBlinkyServiceUUID],
                                    CBAdvertisementDataIsConnectable : true as NSNumber
                                ],
                                advertisingInterval: 0.250, // [ms]
                                proximity: .near)
            
        let hrm = AdvertisingPeripheral(advertisementData: [
                                   CBAdvertisementDataLocalNameKey : "NordicHRM",
                                   CBAdvertisementDataServiceUUIDsKey : [
                                       CBUUID(string: "180D"), // Heart Rate
                                       CBUUID(string: "180A")  // Device Information
                                   ],
                                   CBAdvertisementDataIsConnectable : true as NSNumber
                               ],
                               advertisingInterval: 0.100, // [ms]
                               proximity: .immediate)
                                   
        let beacon = AdvertisingPeripheral(advertisementData: [
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
                              advertisingInterval: 1.000, // [ms]
                              proximity: .far)
            
        return [blinky, hrm, beacon]
    }
    
    func centralManager(_ central: CBCentralManagerMock,
                        initiatedConnectionToPeripheral peripheral: CBPeripheralMock)
        -> ([CBServiceMock], mtu: Int)? {
        if peripheral.identifier == blinkyId {
            let blinkyService = CBServiceMock(
                type: BlinkyPeripheral.nordicBlinkyServiceUUID,
                primary: true)
            let buttonCharacteristic = CBCharacteristicMock(
                type: BlinkyPeripheral.buttonCharacteristicUUID,
                properties: [.notify, .read])
            let cccd = CBClientCharacteristicConfigurationDescriptorMock()
            buttonCharacteristic.descriptors = [cccd]
            let ledCharacteristic = CBCharacteristicMock(
                type: BlinkyPeripheral.ledCharacteristicUUID,
                properties: [.write, .read])
            blinkyService.characteristics = [ledCharacteristic, buttonCharacteristic]
            return ([blinkyService], mtu: 251)
        }
        return nil
    }
    
}
