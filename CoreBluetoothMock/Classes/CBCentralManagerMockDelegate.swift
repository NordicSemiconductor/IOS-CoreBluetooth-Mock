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

public enum MockProximity {
    /// The device will have RSSI values around -40 dBm.
    case near
    /// The device will have RSSI values around -70 dBm.
    case immediate
    /// The device is far, will have RSSI values around -100 dBm.
    case far
    
    internal var RSSI: Int {
        switch self {
        case .near:      return -40
        case .immediate: return -70
        case .far:       return -100
        }
    }
}

public struct AdvertisingPeripheral {
    let identifier: UUID
    let advertisementData: [String : Any]
    let advertisingInterval: TimeInterval
    let proximity: MockProximity
    
    public init(identifier: UUID,
                advertisementData: [String : Any],
                advertisingInterval: TimeInterval,
                proximity: MockProximity) {
        self.identifier = identifier
        self.advertisementData = advertisementData
        self.advertisingInterval = advertisingInterval
        self.proximity = proximity
    }
    
    public init(advertisementData: [String : Any],
                advertisingInterval: TimeInterval,
                proximity: MockProximity) {
        self.identifier = UUID()
        self.advertisementData = advertisementData
        self.advertisingInterval = advertisingInterval
        self.proximity = proximity
    }
}

public protocol CBCentralManagerMockDelegate: class {
    
    /// Method called when the central manager was requested to scan for
    /// nearby Bluetooth LE peripherals. The returned peripherals do not
    /// need to match the service UUID filter. If they don't, they won't
    /// be returned in the scan results, but will get known to the manager
    /// and therefore available using `retrievePeripherals(withIdentifiers:)`.
    /// - Parameters:
    ///   - central: The central manager used for scanning.
    ///   - serviceUUIDs: Optional list of services that will be used for
    ///                   filtering.
    /// - Returns: List of nearby advertising peripheral.
    func centralManager(_ central: CBCentralManagerMock,
                        didStartScanningForPeripheralsWithServices serviceUUIDs: [CBUUID]?) -> [AdvertisingPeripheral]
    
    /// Method called when the central manager initiated connection to the
    /// given peripheral. If the peripheral is connectable, and the connection
    /// should succeed, the method should return list of services. Otherwise
    /// <i>nil</i> should be returned.
    ///
    /// This method will not be called if the peripheral was already connected
    /// by another central manager, or was set as initially connected using
    /// `initiateConnectedPeripheral(name:services:)` in any mock central manager.
    /// - Parameters:
    ///   - central: The central manager used for connection.
    ///   - peripheral: The target peripheral.
    /// - Returns: List of device services, if connection should succeed, or
    ///            <i>nil</i> if device is not connectable or out of range, and
    ///            the MTU. iOS requests MTU 251 by default after connection,
    ///            but the device does not need to support it. The highest
    ///            possible MTU allowed by Bluetooth specification is 517.
    func centralManager(_ central: CBCentralManagerMock,
                        initiatedConnectionToPeripheral peripheral: CBPeripheralMock) -> ([CBServiceMock], mtu: Int)?
}
