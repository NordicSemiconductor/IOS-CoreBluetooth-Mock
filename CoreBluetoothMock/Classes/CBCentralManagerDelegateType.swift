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

public protocol CBCentralManagerDelegateType: class {

    func centralManagerDidUpdateState(_ central: CBCentralManagerType)
    
    func centralManager(_ central: CBCentralManagerType,
                        willRestoreState dict: [String : Any])

    func centralManager(_ central: CBCentralManagerType,
                        didDiscover peripheral: CBPeripheralType,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)

    func centralManager(_ central: CBCentralManagerType,
                        didConnect peripheral: CBPeripheralType)

    func centralManager(_ central: CBCentralManagerType,
                        didFailToConnect peripheral: CBPeripheralType,
                        error: Error?)

    func centralManager(_ central: CBCentralManagerType,
                        didDisconnectPeripheral peripheral: CBPeripheralType,
                        error: Error?)
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManagerType,
                        connectionEventDidOccur event: CBConnectionEvent,
                        for peripheral: CBPeripheralType)
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManagerType,
                        didUpdateANCSAuthorizationFor peripheral: CBPeripheralType)
}

public extension CBCentralManagerDelegateType {
    
    func centralManager(_ central: CBCentralManagerType,
                        willRestoreState dict: [String : Any]) {
        // optional method
    }
    
    func centralManager(_ central: CBCentralManagerType,
                        didDiscover peripheral: CBPeripheralType,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // optional method
    }
    
    func centralManager(_ central: CBCentralManagerType,
                        didConnect peripheral: CBPeripheralType) {
        // optional method
    }
    
    func centralManager(_ central: CBCentralManagerType,
                        didFailToConnect peripheral: CBPeripheralType,
                        error: Error?) {
        // optional method
    }
    
    func centralManager(_ central: CBCentralManagerType,
                        didDisconnectPeripheral peripheral: CBPeripheralType,
                        error: Error?) {
        // optional method
    }
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManagerType,
                        connectionEventDidOccur event: CBConnectionEvent,
                        for peripheral: CBPeripheralType) {
        // optional method
    }
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManagerType,
                        didUpdateANCSAuthorizationFor peripheral: CBPeripheralType) {
        // optional method
    }
}
