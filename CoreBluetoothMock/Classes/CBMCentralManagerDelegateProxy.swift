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

import CoreBluetooth

/// A helper class that allows setting delegate callbacks as closures.
///
/// - SeeAlso: ``CBMCentralManagerDelegate``
open class CBMCentralManagerDelegateProxy: NSObject, CBMCentralManagerDelegate {
    public var didUpdateState: ((CBMCentralManager) -> ())?
    public var willRestoreState: ((CBMCentralManager, [String : Any]) -> ())?
    public var didDiscoverPeripheral: ((CBMCentralManager, CBMPeripheral, [String : Any], NSNumber) -> ())?
    public var didConnect: ((CBMCentralManager, CBMPeripheral) -> ())?
    public var didFailToConnect: ((CBMCentralManager, CBMPeripheral, Error?) -> ())?
    public var didDisconnect: ((CBMCentralManager, CBMPeripheral, Error?) -> ())?
    public var connectionEventDidOccur: ((CBMCentralManager, CBMConnectionEvent, CBMPeripheral) -> ())?
    public var didUpdateANCSAuthorization: ((CBMCentralManager, CBMPeripheral) -> ())?
    
    open func centralManagerDidUpdateState(_ central: CBMCentralManager) {
        didUpdateState?(central)
    }
    
    open func centralManager(_ central: CBMCentralManager,
                               willRestoreState dict: [String : Any]) {
        willRestoreState?(central, dict)
    }
    
    open func centralManager(_ central: CBMCentralManager,
                               didDiscover peripheral: CBMPeripheral,
                               advertisementData: [String : Any],
                               rssi RSSI: NSNumber) {
        didDiscoverPeripheral?(central, peripheral, advertisementData, RSSI)
    }
    
    open func centralManager(_ central: CBMCentralManager,
                               didConnect peripheral: CBMPeripheral) {
        didConnect?(central, peripheral)
    }
    
    open func centralManager(_ central: CBMCentralManager,
                               didFailToConnect peripheral: CBMPeripheral,
                               error: Error?) {
        didFailToConnect?(central, peripheral, error)
    }
    
    open func centralManager(_ central: CBMCentralManager,
                               didDisconnectPeripheral peripheral: CBMPeripheral,
                               error: Error?) {
        didDisconnect?(central, peripheral, error)
    }
    
    @available(iOS 13.0, *)
    open func centralManager(_ central: CBMCentralManager,
                               connectionEventDidOccur event: CBMConnectionEvent,
                               for peripheral: CBMPeripheral) {
        connectionEventDidOccur?(central, event, peripheral)
    }
    
    @available(iOS 13.0, *)
    open func centralManager(_ central: CBMCentralManager,
                               didUpdateANCSAuthorizationFor peripheral: CBMPeripheral) {
        didUpdateANCSAuthorization?(central, peripheral)
    }
}
