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
    /// The device is out of range.
    case outOfRange
    
    internal var RSSI: Int {
        switch self {
        case .near:       return -40
        case .immediate:  return -70
        case .far:        return -100
        case .outOfRange: return -128
        }
    }
}

public class MockPeripheral {
    /// The peripheral identifier.
    public let identifier: UUID
    /// The name of the peripheral cached during previous session.
    /// This may be <i>nil<i/> to simulate a newly discovered devices.
    public internal(set) var name: String?
    /// How far the device is.
    public internal(set) var proximity: MockProximity
    /// Should the mock peripheral appear in scan results when it's
    /// connected.
    public let isAdvertisingWhenConnected: Bool
    
    /// The device's advertising data.
    /// Make sure to include `CBAdvertisementDataIsConnectable` if the
    /// device is connectable.
    public let advertisementData: [String : Any]?
    /// The advertising interval.
    public let advertisingInterval: TimeInterval?
    
    /// List of services with implementation.
    public internal(set) var services: [CBServiceMock]?
    /// The connection interval.
    public let connectionInterval: TimeInterval?
    /// The MTU (Maximum Transfer Unit). Min value is 23, max 517.
    /// The maximum value length for Write Without Response is
    /// MTU - 3 bytes.
    public let mtu: Int?
    /// The delegate that will handle connection requests.
    public let connectionDelegate: MockPeripheralDelegate?
    /// A flag indicating whether the device is connected.
    public var isConnected: Bool {
        return virtualConnections > 0
    }
    /// Number of virtual connections to this peripheral. A peripheral
    /// may be connected using multiple central managers in one or
    /// multiple apps. When this drops to 0, the device is physically
    /// disconnected.
    internal var virtualConnections: Int
    
    private init(
            identifier: UUID,
            name: String?,
            proximity: MockProximity,
            isInitiallyConnected: Bool,
            isAdvertisingWhenConnected: Bool,
            advertisementData: [String : Any]?,
            advertisingInterval: TimeInterval?,
            services: [CBServiceMock]?,
            connectionInterval: TimeInterval?,
            mtu: Int?,
            connectionDelegate: MockPeripheralDelegate?) {
        self.identifier = identifier
        self.name = name
        self.proximity = proximity
        self.virtualConnections = isInitiallyConnected ? 1 : 0
        self.isAdvertisingWhenConnected = isAdvertisingWhenConnected
        self.advertisementData = advertisementData
        self.advertisingInterval = advertisingInterval
        self.services = services
        self.connectionInterval = connectionInterval
        self.mtu = mtu
        self.connectionDelegate = connectionDelegate
    }
    
    /// Creates a `MockPeripheral.Builder` instance.
    /// Use builder methods to customize your device and call `build()` to
    /// return the `MockPeripheral` object.
    /// - Parameters:
    ///   - identifier: The peripheral identifier. If not given, a random
    ///                 UUID will be used.
    ///   - proximity: Approximate distance to the device. By default set
    ///                to `.immediate`.
    public static func simulatePeripheral(identifier: UUID = UUID(),
                                          proximity: MockProximity = .immediate) -> Builder {
        return Builder(identifier: identifier,
                       proximity: proximity)
    }
    
    /// Simulates the situation when another application on the device
    /// connects to the device.
    ///
    /// If `isAdvertisingWhenConnected` flag is set to <i>false</i>, the
    /// device will stop showing up on scan results.
    ///
    /// A manager registered for connection event will receive an event.
    ///
    /// Connected devices are be available for managers using
    /// `retrieveConnectedPeripherals(withServices:)`.
    public func simulateConnection() {
        CBCentralManagerMock.peripheralDidConnect(self)
    }
    
    /// Simulates a situation when the peripheral disconnection from
    /// the device.
    ///
    /// All connected mock central managers will receive
    /// `peripheral(:didDisconnected:error)` callback.
    /// - Parameter error: The disconnection reason. Use `CBError` or
    ///                    `CBATTError` errors.
    public func simulateDisconnection(withError error: Error = CBError(.peripheralDisconnected)) {
        CBCentralManagerMock.peripheral(self, didDisconnectWithError: error)
    }
    
    /// Simulates a reset of the peripheral. It will make it advertising
    /// again (if advertising was enabled) immediately. Connected central
    /// managers will be notified after the supervision timeout is over.
    public func simulateReset() {
        simulateDisconnection(withError: CBError(.connectionTimeout))
    }
    
    /// Simulates a situation when the device changes its services.
    ///
    /// The device must be connectable, otherwise this method does
    /// nothing.
    /// - Parameters:
    ///   - newName: The new device name after change.
    ///   - newServices: The new services after change.
    public func simulateServiceChange(newName: String?,
                                      newServices: [CBServiceMock]) {
        guard let _ = connectionDelegate else {
            return
        }
        CBCentralManagerMock.peripheral(self, didUpdateName: newName,
                                        andServices: newServices)
    }
    
    /// Simulates a situation when the peripheral was moved closer
    /// or away from the phone.
    ///
    /// If the proximity is changed to `.outOfRange`, the peripheral will
    /// be disconnected and will not appear on scan results.
    /// - Parameter peripheral: The peripheral that
    /// - Parameter proximity: The new peripheral proximity.
    public func simulateProximityChange(_ proximity: MockProximity) {
        CBCentralManagerMock.proximity(of: self, didChangeTo: proximity)
    }
    
    public class Builder {
        /// The peripheral identifier.
        private var identifier: UUID
        /// The name of the peripheral cached during previous session.
        /// This may be <i>nil<i/> to simulate a newly discovered devices.
        private var name: String?
        /// How far the device is.
        private var proximity: MockProximity
             
        /// The device's advertising data.
        /// Make sure to include `CBAdvertisementDataIsConnectable` with
        /// value <i>true</i> if the device is connectable.
        private var advertisementData: [String : Any]? = nil
        /// The advertising interval, in seconds.
        private var advertisingInterval: TimeInterval? = 0.100
        
        /// Should the mock peripheral appear in scan results when it's
        /// connected.
        private var isAdvertisingWhenConnected: Bool = false
        /// A flag indicating whether the device is initially connected
        /// to the central (using some other application).
        private var isInitiallyConnected: Bool = false
        
        /// List of services with implementation.
        private var services: [CBServiceMock]? = nil
        /// The connection interval, in seconds.
        private var connectionInterval: TimeInterval? = nil
        /// The MTU (Maximul Transfer Unit). Min value is 23, max 517.
        /// The maximum value length for Write Without Response is
        /// MTU - 3 bytes.
        private var mtu: Int? = nil
        /// The delegate that will handle connection requests.
        private var connectionDelegate: MockPeripheralDelegate?
        
        fileprivate init(identifier: UUID, proximity: MockProximity) {
            self.identifier = identifier
            self.proximity = proximity
        }
        
        /// Makes the device advertising given data with specified advertising
        /// interval.
        /// - Parameters:
        ///   - advertisementData: The advertising data.
        ///   - interval: Advertising interval, in seconds.
        ///   - advertisignWhenConnected: If <i>true</i>, the device will also
        ///                               be returned in scan results when
        ///                               connected. By default set to
        ///                               <i>false</i>.
        /// - Returns: The builder.
        public func advertising(advertisementData: [String : Any],
                                withInterval interval: TimeInterval = 0.100,
                                alsoWhenConnected advertisignWhenConnected: Bool = false) -> Builder {
            self.advertisementData = advertisementData
            self.advertisingInterval = interval
            self.isAdvertisingWhenConnected = advertisignWhenConnected
            return self
        }
        
        /// Makes the device connnectable, but not connected at the moment
        /// of initialization.
        /// - Parameters:
        ///   - name: The device name, returned by Device Name characteristic.
        ///   - services: List of services that will be returned from service
        ///               discovery.
        ///   - connectionDelegate: The connection delegate that will handle
        ///                         GATT requests.
        ///   - connectionInterval: Connection interval, in seconds.
        ///   - mtu: The MTU (Maximum Transfer Unit). Min 23 (default), max 517.
        ///          The maximum value length for Write Without Response is
        ///          MTU - 3 bytes (3 bytes are used by GATT for handle and
        ///          command).
        public func connectable(name: String,
                                services: [CBServiceMock],
                                delegate: MockPeripheralDelegate?,
                                connectionInterval: TimeInterval = 0.045,
                                mtu: Int = 23) -> Builder {
            self.name = name
            self.services = services
            self.connectionDelegate = delegate
            self.connectionInterval = connectionInterval
            self.mtu = max(23, min(517, mtu))
            self.isInitiallyConnected = false
            return self
        }
        
        /// Makes the device connnectable, and also marks already connected
        /// by some other application. Such device, if not advertising,
        /// can be obtained using `retrieveConnectedPeripherals(withServices:)`.
        /// - Parameters:
        ///   - name: The device name, returned by Device Name characteristic.
        ///   - services: List of services that will be returned from service
        ///               discovery.
        ///   - connectionDelegate: The connection delegate that will handle
        ///                         GATT requests.
        ///   - connectionInterval: Connection interval, in seconds.
        ///   - mtu: The MTU (Maximum Transfer Unit). Min 23 (default), max 517.
        ///          The maximum value length for Write Without Response is
        ///          MTU - 3 bytes (3 bytes are used by GATT for handle and
        ///          command).
        public func connected(name: String,
                              services: [CBServiceMock],
                              delegate: MockPeripheralDelegate?,
                              connectionInterval: TimeInterval = 0.045,
                              mtu: Int = 23)-> Builder {
            self.name = name
            self.services = services
            self.connectionDelegate = delegate
            self.connectionInterval = connectionInterval
            self.mtu = mtu
            self.isInitiallyConnected = true
            return self
        }
        
        /// Builds the `MockPeripheral` object.
        public func build() -> MockPeripheral {
            return MockPeripheral(
                identifier: identifier,
                name: name,
                proximity: proximity,
                isInitiallyConnected: isInitiallyConnected,
                isAdvertisingWhenConnected: isAdvertisingWhenConnected,
                advertisementData: advertisementData,
                advertisingInterval: advertisingInterval,
                services: services,
                connectionInterval: connectionInterval,
                mtu: mtu,
                connectionDelegate: connectionDelegate
            )
        }
    }
}

extension MockPeripheral: Equatable {
    
    public static func == (lhs: MockPeripheral, rhs: MockPeripheral) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
