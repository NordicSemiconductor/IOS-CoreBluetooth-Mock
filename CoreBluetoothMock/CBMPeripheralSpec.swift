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

/// Advertisement configuration.
///
/// This config includes the advertisement data, interval, initial delay and a flag
/// indicating whether the advertisement is also broadcasted when the device is in
/// connected state.
///
/// The advertisement config is set in ``CBMPeripheralSpec/Builder/advertising(advertisementData:withInterval:delay:alsoWhenConnected:)``
/// and can be changed during simulation using
/// ``CBMPeripheralSpec/simulateAdvertisementChange(_:)``.
public struct CBMAdvertisementConfig {
    /// ID used for hash.
    internal let id: UUID = UUID()
    
    /// The device's advertising data.
    public let data: [String : Any]
    /// The advertising interval.
    ///
    /// If the interval is 0, the advertisement will be fired only once. In that case use the `delay`
    /// parameter to specify when the advertisement is to be sent.
    public let interval: TimeInterval
    /// The delay of the first advertising packet of that type.
    ///
    /// If the delay is 0, the library will mock advertisements in regular intervals.
    ///
    /// The delay is counted from the time the mock peripheral was added to the simulation
    /// using ``CBMCentralManagerMock/simulatePeripherals(_:)``.
    ///
    /// - Note: The devices are advertising also when there are no central managers scanning.
    public let delay: TimeInterval
    /// Should the mock peripheral appear in scan results when it's
    /// connected.
    public let isAdvertisingWhenConnected: Bool
    
    /// Creates an advertising configuration.
    /// - Parameters:
    ///   - data: The data that will be advertised. Only the iOS-supported keys are available.
    ///   - interval: The advertising interval in seconds.
    ///   - delay: The delay to the first packet, in seconds.
    ///   - isAdvertisingWhenConnected: Whether the device advertises also when in
    ///                                 connected state.
    public init(data: [String : Any],
                interval: TimeInterval, delay: TimeInterval = 0.0,
                isAdvertisingWhenConnected: Bool = false) {
        self.data = data
        self.interval = interval
        self.delay = delay
        self.isAdvertisingWhenConnected = isAdvertisingWhenConnected
    }
}

/// Specification of a mock peripheral.
///
/// This specification should represent the behavior of a real Bluetooth LE device as much as possible.
///
/// Use ``CBMPeripheralSpec/simulatePeripheral(identifier:proximity:)`` to
/// create a new instance builder.
public class CBMPeripheralSpec {
    /// The peripheral identifier.
    public internal(set) var identifier: UUID
    /// The name of the peripheral returned by Device Name characteristic.
    public internal(set) var name: String?
    /// How far the device is.
    public internal(set) var proximity: CBMProximity
    /// A flag indicating that the peripheral can be obtained using
    /// ``CBMCentralManagerMock/retrievePeripherals(withIdentifiers:)``
    /// without scanning. This is set to true whenever the peripheral
    /// gets scanned, but can also be forced using
    /// ``CBMPeripheralSpec/Builder/allowForRetrieval()``
    /// or ``CBMPeripheralSpec/simulateCaching()``.
    ///
    /// When set, the system has scanned for this device
    /// previously and stored its UUID.
    public internal(set) var isKnown: Bool
    
    /// Advertisement configurations of the peripheral.
    ///
    /// A device can advertise with multiple packets with different advertising interval and
    /// initial delay.
    /// - Since: 0.15.0
    public internal(set) var advertisement: [CBMAdvertisementConfig]?
    
    /// The device's advertising data.
    ///
    /// This property was deprecated in version 0.15.0 with added support for multiple
    /// advertisements per peripheral. Use ``CBMPeripheralSpec/advertisement`` instead.
    @available(*, deprecated, message: "Use advertisement configurations instead")
    public var advertisementData: [String : Any]? {
        return advertisement?.first?.data
    }
    /// The advertising interval.
    ///
    /// This property was deprecated in version 0.15.0 with added support for multiple
    /// advertisements per peripheral. Use ``CBMPeripheralSpec/advertisement`` instead.
    @available(*, deprecated, message: "Use advertisement configurations instead")
    public var advertisingInterval: TimeInterval? {
        return advertisement?.first?.interval
    }
    /// Should the mock peripheral appear in scan results when it's connected.
    ///
    /// This property was deprecated in version 0.15.0 with added support for multiple
    /// advertisements per peripheral. Use ``CBMPeripheralSpec/advertisement`` instead.
    @available(*, deprecated, message: "Use advertisement configurations instead")
    public var isAdvertisingWhenConnected: Bool {
        return advertisement?.first?.isAdvertisingWhenConnected ?? false
    }
    
    /// List of services available for service discovery.
    public internal(set) var services: [CBMServiceMock]?
    /// The connection interval.
    public let connectionInterval: TimeInterval?
    /// The MTU (Maximum Transfer Unit).
    ///
    /// Min value is 23, max 517.
    ///
    /// The maximum value length for Write Without Response is MTU - 3 bytes, as 3 bytes
    /// are reserved for the Handle number and Op Code on the GATT layer.
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
    /// This flag indicates whether the device was connected and cached
    /// by the system.
    ///
    /// On the first connection iOS reads and caches Device Name characteristic.
    internal var wasConnected: Bool
    
    private init(
        identifier: UUID,
        name: String?,
        proximity: CBMProximity,
        isInitiallyConnected: Bool,
        isKnown: Bool,
        advertisement: [CBMAdvertisementConfig]?,
        services: [CBMServiceMock]?,
        connectionInterval: TimeInterval?,
        mtu: Int?,
        connectionDelegate: CBMPeripheralSpecDelegate?
    ) {
        self.identifier = identifier
        self.name = name
        self.proximity = proximity
        self.virtualConnections = isInitiallyConnected ? 1 : 0
        self.isKnown = isKnown
        self.advertisement = advertisement
        self.services = services
        self.connectionInterval = connectionInterval
        self.mtu = mtu
        self.connectionDelegate = connectionDelegate
        self.wasConnected = isInitiallyConnected
    }
    
    /// Creates a ``CBMPeripheralSpec/Builder`` instance, which can be used to define
    /// the behavior or a mocked peripheral.
    ///
    /// Use builder's methods to customize your device and call ``CBMPeripheralSpec/Builder/build()``
    /// to create the ``CBMPeripheralSpec`` object.
    /// - Parameters:
    ///   - identifier: The peripheral identifier. If not given, a random
    ///                 UUID will be used.
    ///   - proximity: Approximate distance to the device. By default set
    ///                to ``CBMProximity/immediate``.
    public static func simulatePeripheral(identifier: UUID = UUID(),
                                          proximity: CBMProximity = .immediate) -> Builder {
        return Builder(identifier: identifier, proximity: proximity)
    }
    
    /// Simulates the situation when another application on the device
    /// connects to the device.
    ///
    /// If the device has advertisement configuration with
    /// ``CBMAdvertisementConfig/isAdvertisingWhenConnected`` flag set
    /// to `false`, the given advertisement will stop showing up on scan results.
    ///
    /// A manager registered for connection event will receive an event.
    ///
    /// Connected devices are be available for managers using
    /// ``CBMCentralManager/retrieveConnectedPeripherals(withServices:)``.
    ///
    /// - Note: The peripheral needs to be in range.
    public func simulateConnection() {
        guard proximity != .outOfRange else {
            return
        }
        CBMCentralManagerMock.peripheralDidConnect(self)
    }
    
    /// Simulates peripheral disconnection from the device.
    ///
    /// All connected mock central managers will receive
    /// ``CBMCentralManagerDelegate/centralManager(_:didDisconnectPeripheral:error:)-1lv48`` callback.
    /// - Parameter error: The disconnection reason. Use ``CBMError`` or
    ///                    ``CBMATTError`` errors.
    public func simulateDisconnection(withError error: Error = CBMError(.peripheralDisconnected)) {
        CBMCentralManagerMock.peripheral(self, didDisconnectWithError: error)
    }
    
    /// Simulates a reset of the peripheral.
    ///
    /// The peripheral will start advertising again (if advertising was enabled) immediately.
    /// Connected central managers will be notified after the supervision timeout is over.
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
    /// If the proximity is changed to ``CBMProximity/outOfRange``, the peripheral will
    /// be disconnected and will not appear on scan results.
    /// - Parameter proximity: The new peripheral proximity.
    public func simulateProximityChange(_ proximity: CBMProximity) {
        CBMCentralManagerMock.proximity(of: self, didChangeTo: proximity)
    }
    
    /// Simulates a notification/indication sent from the peripheral.
    ///
    /// All central managers that have enabled notifications on it
    /// will receive ``CBMPeripheralDelegate/peripheral(_:didUpdateValueFor:error:)-62302``.
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
    
    /// Simulates a change in the advertising packet.
    ///
    /// The delays in the config will be applied from the time this method is called.
    /// - Parameter advertisement: The new advertising configuration.
    /// - Since: 0.15.0
    public func simulateAdvertisementChange(_ advertisement: [CBMAdvertisementConfig]?) {
        CBMCentralManagerMock.peripheral(self, didChangeAdvertisement: advertisement)
    }
    
    /// Simulates a situation when the iDevice scans for Bluetooth LE devices
    /// and caches scanned results. Scanned devices become available for retrieval
    /// using ``CBMCentralManager/retrievePeripherals(withIdentifiers:)``.
    ///
    /// When scanning is performed by a mock central manager, and the device is
    /// in range, this gets called automatically.
    public func simulateCaching() {
        isKnown = true
    }
    
    /// Simulates a change of the device's MAC address.
    ///
    /// MAC addresses are not available through iOS API. Each MAC gets
    /// assigned a UUID by which the device can be identified and retrieved
    /// after it has been scanned and cached.
    ///
    /// If a device is connected, this will not cause disconnection.
    /// - Parameter newIdentifier: The new peripheral identifier.
    public func simulateMacChange(_ newIdentifier: UUID = UUID()) {
        isKnown = false
        identifier = newIdentifier
    }
    
    /// Defines the behavior of ``CBMPeripheralSpec`` object.
    ///
    /// The builder should be used to create a mock implementation of a real peripheral device.
    ///
    /// Call ``CBMPeripheralSpec/Builder/build()`` to create a mock peripheral specification.
    public class Builder {
        /// The peripheral identifier.
        private var identifier: UUID
        /// The name of the peripheral cached during previous session.
        /// This may be `nil` to simulate a newly discovered devices.
        private var name: String?
        /// How far the device is.
        private var proximity: CBMProximity
        
        /// A flag indicating whether the device is initially connected
        /// to the central (using some other application).
        private var isInitiallyConnected: Bool = false
        /// A flag indicating that the peripheral can be obtained using
        /// ``CBMCentralManagerMock/retrievePeripherals(withIdentifiers:)``
        /// without scanning.
        ///
        /// When set to true, it means the system has scanned for this device
        /// previously and stored its UUID.
        private var isKnown: Bool = false
        
        /// The device's advertising data.
        private var advertisement: [CBMAdvertisementConfig]? = nil
        /// List of services with implementation.
        private var services: [CBMServiceMock]? = nil
        /// The connection interval, in seconds.
        private var connectionInterval: TimeInterval? = nil
        /// The MTU (Maximum Transfer Unit). Min value is 23, max 517.
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
        ///   - interval: Advertising interval, in seconds. Use 0 for one time advertisements.
        ///   - delay: The delay of the first packet of that type, counted from when the peripheral
        ///            is added to the simulation.
        ///   - advertisingWhenConnected: If `true`, the device will also
        ///                               be returned in scan results when
        ///                               connected. By default set to
        ///                               `false`.
        /// - Returns: The builder.
        /// - Note: Starting from version 0.15.0 this method may be called multiple times
        ///         if the device advertises with multiple different packets.
        public func advertising(advertisementData: [String : Any],
                                withInterval interval: TimeInterval = 0.100,
                                delay: TimeInterval = 0.0,
                                alsoWhenConnected advertisingWhenConnected: Bool = false) -> Builder {
            if self.advertisement == nil {
                self.advertisement = []
            }
            self.advertisement!.append(
                CBMAdvertisementConfig(
                    data: advertisementData,
                    interval: interval,
                    delay: delay,
                    isAdvertisingWhenConnected: advertisingWhenConnected)
            )
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
        /// can be obtained using ``CBMCentralManager/retrieveConnectedPeripherals(withServices:)``.
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
        /// ``CBMCentralManagerMock/retrievePeripherals(withIdentifiers:)``
        /// without scanning.
        ///
        /// That means, that the manager has perviously scanned and cached the
        /// peripheral and can obtain it by the identifier.
        public func allowForRetrieval() -> Builder {
            self.isKnown = true
            return self
        }
        
        /// Builds the ``CBMPeripheralSpec`` object.
        public func build() -> CBMPeripheralSpec {
            return CBMPeripheralSpec(
                identifier: identifier,
                name: name,
                proximity: proximity,
                isInitiallyConnected: isInitiallyConnected,
                isKnown: isKnown,
                advertisement: advertisement,
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

extension CBMAdvertisementConfig: Hashable {
    
    public static func == (lhs: CBMAdvertisementConfig, rhs: CBMAdvertisementConfig) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
