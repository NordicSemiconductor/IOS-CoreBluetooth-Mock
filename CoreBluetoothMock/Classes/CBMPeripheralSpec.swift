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

/// The approximate mock device proximity.
public enum CBMProximity {
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
        case .outOfRange: return 127
        }
    }
}

/// The peripheral instance specification.
public class CBMPeripheralSpec {
    /// The peripheral identifier.
    public let identifier: UUID
    /// The name of the peripheral usually returned by Device Name
    /// characteristic.
    public internal(set) var name: String?
    /// How far the device is.
    public internal(set) var proximity: CBMProximity
    /// Should the mock peripheral appear in scan results when it's
    /// connected.
    public let isAdvertisingWhenConnected: Bool
    /// A flag indicating that the peripheral can be obtained using
    /// `CBMCentralManagerMock.retrievePeripherals(withIdentifiers:)`
    /// without scanning. This is set to true whenever the peripheral
    /// gets scanned, but can also be forced using `Builder.allowForRetrieval()`
    /// or `simulateCached()`.
    ///
    /// When set to true, it means the system has scanned for this device
    /// previously and stored its UUID.
    public internal(set) var isKnown: Bool
    
    /// The device's advertising data.
    /// Make sure to include `CBAdvertisementDataIsConnectable` if
    /// the device is connectable.
    public let advertisementData: [String : Any]?
    /// The advertising interval.
    public let advertisingInterval: TimeInterval?
    
    /// List of services with implementation.
    public internal(set) var services: [CBMServiceMock]?
    /// The connection interval.
    public let connectionInterval: TimeInterval?
    /// The MTU (Maximum Transfer Unit). Min value is 23, max 517.
    /// The maximum value length for Write Without Response is
    /// MTU - 3 bytes.
    public let mtu: Int?
    /// The delegate that will handle connection requests.
    public let connectionDelegate: CBMPeripheralSpecDelegate?
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
        proximity: CBMProximity,
        isInitiallyConnected: Bool,
        isAdvertisingWhenConnected: Bool,
        isKnown: Bool,
        advertisementData: [String : Any]?,
        advertisingInterval: TimeInterval?,
        services: [CBMServiceMock]?,
        connectionInterval: TimeInterval?,
        mtu: Int?,
        connectionDelegate: CBMPeripheralSpecDelegate?
    ) {
        self.identifier = identifier
        self.name = name
        self.proximity = proximity
        self.virtualConnections = isInitiallyConnected ? 1 : 0
        self.isAdvertisingWhenConnected = isAdvertisingWhenConnected
        self.isKnown = isKnown
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
                                          proximity: CBMProximity = .immediate) -> Builder {
        return Builder(identifier: identifier, proximity: proximity)
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
    ///
    /// - Note: The peripheral needs to be in range.
    public func simulateConnection() {
        guard proximity != .outOfRange else {
            return
        }
        CBMCentralManagerMock.peripheralDidConnect(self)
    }
    
    /// Simulates a situation when the peripheral disconnection from
    /// the device.
    ///
    /// All connected mock central managers will receive
    /// `peripheral(:didDisconnected:error)` callback.
    /// - Parameter error: The disconnection reason. Use `CBMError` or
    ///                    `CBMATTError` errors.
    public func simulateDisconnection(withError error: Error = CBMError(.peripheralDisconnected)) {
        CBMCentralManagerMock.peripheral(self, didDisconnectWithError: error)
    }
    
    /// Simulates a reset of the peripheral. The peripheral will start
    /// advertising again (if advertising was enabled) immediately.
    /// Connected central managers will be notified after the supervision
    /// timeout is over.
    public func simulateReset() {
        connectionDelegate?.reset()
        simulateDisconnection(withError: CBMError(.connectionTimeout))
    }
    
    /// Simulates a situation when the device changes its services.
    /// Only services that were not in the previous list of services
    /// will be reported as invalidated.
    ///
    /// The device must be connectable, otherwise this method does
    /// nothing.
    /// - Important: In the mock implementation the order of services
    ///              is irrelevant. This is in contrary to the physical
    ///              Bluetooth LE device, where handle numbers depend
    ///              on order of the services in the attribute database.
    /// - Parameters:
    ///   - newName: The new device name after change.
    ///   - newServices: The new services after change.
    public func simulateServiceChange(newName: String?,
                                      newServices: [CBMServiceMock]) {
        guard let _ = connectionDelegate else {
            return
        }
        CBMCentralManagerMock.peripheral(self, didUpdateName: newName,
                                         andServices: newServices)
    }
    
    /// Simulates a situation when the peripheral was moved closer
    /// or away from the phone.
    ///
    /// If the proximity is changed to `.outOfRange`, the peripheral will
    /// be disconnected and will not appear on scan results.
    /// - Parameter proximity: The new peripheral proximity.
    public func simulateProximityChange(_ proximity: CBMProximity) {
        CBMCentralManagerMock.proximity(of: self, didChangeTo: proximity)
    }
    
    /// Simulates a notification/indication sent from the peripheral.
    ///
    /// All central managers that have enabled notifications on it
    /// will receive `peripheral(:didUpdateValueFor:error)`.
    /// - Parameters:
    ///   - data: The notification/indication data.
    ///   - characteristic: The characteristic from which a
    ///                     notification or indication is to be sent.
    public func simulateValueUpdate(_ data: Data,
                                    for characteristic: CBMCharacteristicMock) {
        guard let services = services,
              services.contains(where: {
                  $0.characteristics?.contains(characteristic) ?? false
              }) else {
            return
        }
        characteristic.value = data
        CBMCentralManagerMock.peripheral(self, didUpdateValueFor: characteristic)
    }
    
    /// Simulates a situation when the iDevice scans for Bluetooth LE devices
    /// and caches scanned results. Scanned devices become available for retrieval
    /// using `CBMCentralManager.retrievePeripherals(withIdentifiers:)`.
    ///
    /// When scanning is performed by a mock central manager, and the device is
    /// in range, this gets called automatically.
    public func simulateCaching() {
        isKnown = true
    }
    
    public class Builder {
        /// The peripheral identifier.
        private var identifier: UUID
        /// The name of the peripheral cached during previous session.
        /// This may be <i>nil<i/> to simulate a newly discovered devices.
        private var name: String?
        /// How far the device is.
        private var proximity: CBMProximity
             
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
        /// A flag indicating that the peripheral can be obtained using
        /// `CBMCentralManagerMock.retrievePeripherals(withIdentifiers:)`
        /// without scanning.
        ///
        /// When set to true, it means the system has scanned for this device
        /// previously and stored its UUID.
        private var isKnown: Bool = false
        
        /// List of services with implementation.
        private var services: [CBMServiceMock]? = nil
        /// The connection interval, in seconds.
        private var connectionInterval: TimeInterval? = nil
        /// The MTU (Maximul Transfer Unit). Min value is 23, max 517.
        /// The maximum value length for Write Without Response is
        /// MTU - 3 bytes.
        private var mtu: Int? = nil
        /// The delegate that will handle connection requests.
        private var connectionDelegate: CBMPeripheralSpecDelegate?
        
        fileprivate init(identifier: UUID, proximity: CBMProximity) {
            self.identifier = identifier
            self.proximity = proximity
        }
        
        /// Makes the device advertising given data with specified advertising
        /// interval.
        /// - Parameters:
        ///   - advertisementData: The advertising data.
        ///   - interval: Advertising interval, in seconds.
        ///   - advertisingWhenConnected: If <i>true</i>, the device will also
        ///                               be returned in scan results when
        ///                               connected. By default set to
        ///                               <i>false</i>.
        /// - Returns: The builder.
        public func advertising(advertisementData: [String : Any],
                                withInterval interval: TimeInterval = 0.100,
                                alsoWhenConnected advertisingWhenConnected: Bool = false) -> Builder {
            self.advertisementData = advertisementData
            self.advertisingInterval = interval
            self.isAdvertisingWhenConnected = advertisingWhenConnected
            return self
        }
        
        /// Makes the device connectable, but not connected at the moment
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
                                services: [CBMServiceMock],
                                delegate: CBMPeripheralSpecDelegate?,
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
        
        /// Makes the device connectable, and also marks already connected
        /// by some other application. Such device, if not advertising,
        /// can be obtained using `retrieveConnectedPeripherals(withServices:)`.
        /// - Note: The peripheral needs to be in range.
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
                              services: [CBMServiceMock],
                              delegate: CBMPeripheralSpecDelegate?,
                              connectionInterval: TimeInterval = 0.045,
                              mtu: Int = 23) -> Builder {
            self.name = name
            self.services = services
            self.connectionDelegate = delegate
            self.connectionInterval = connectionInterval
            self.mtu = max(23, min(517, mtu))
            self.isInitiallyConnected = proximity != .outOfRange
            self.isKnown = true
            return self
        }
        
        /// Make the peripheral available through
        /// `CBMCentralManagerMock.retrievePeripherals(withIdentifiers:)`
        /// without scanning.
        ///
        /// That means, that the manager has perviously scanned and cached the
        /// peripheral and can obtain it by the identfier.
        public func allowForRetrieval() -> Builder {
            self.isKnown = true
            return self
        }
        
        /// Builds the `MockPeripheral` object.
        public func build() -> CBMPeripheralSpec {
            return CBMPeripheralSpec(
                identifier: identifier,
                name: name,
                proximity: proximity,
                isInitiallyConnected: isInitiallyConnected,
                isAdvertisingWhenConnected: isAdvertisingWhenConnected,
                isKnown: isKnown,
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

extension CBMPeripheralSpec: Equatable {
    
    public static func == (lhs: CBMPeripheralSpec, rhs: CBMPeripheralSpec) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
