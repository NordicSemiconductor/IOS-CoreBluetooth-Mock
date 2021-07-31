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

public protocol CBMPeripheral: AnyObject {
    
    /// The UUID associated with the peer.
    ///
    /// The value of this property represents the unique identifier of the
    /// peer. The first time a local manager encounters a peer, the system
    /// assigns the peer a UUID, represented by a new UUID object. Peers
    /// use UUID instances to identify themselves, instead of by the `CBMUUID`
    /// objects that identify a peripheral’s services, characteristics, and
    /// descriptors.
    var identifier: UUID { get }
    
    /// The delegate object specified to receive peripheral events.
    ///
    /// For information about how to implement your peripheral delegate,
    /// see `CBMPeripheralDelegate`.
    var delegate: CBMPeripheralDelegate? { get set }
    
    /// The name of the peripheral.
    ///
    /// Use this property to retrieve a human-readable name of the
    /// peripheral. A peripheral may have two different name types: one
    /// that the device advertises and another that the device publishes in
    /// its database as its Bluetooth low energy Generic Access Profile
    /// (GAP) device name. If a peripheral has both types of names, this
    /// property returns its GAP device name.
    var name: String? { get }
    
    /// The connection state of the peripheral.
    ///
    /// This property represents the current connection state of the
    /// peripheral. For a list of the possible values, see
    /// `CBMPeripheralState`.
    var state: CBMPeripheralState { get }
    
    /// A list of a peripheral’s discovered services.
    ///
    /// Returns an array of services (represented by `CBMService` objects)
    /// that successful call to the `discoverServices(_:)` method discovered.
    /// If you haven’t yet called the `discoverServices(_:)` method to
    /// discover the services of the peripheral, or if there was an error
    /// in doing so, the value of this property is nil.
    var services: [CBMService]? { get }
    
    /// A Boolean value that indicates whether the remote device can send a
    /// write without a response.
    ///
    /// If this value is false, flushing all current writes sets the value
    /// to true. This also results in a call to the delegate’s
    /// `peripheralIsReady(toSendWriteWithoutResponse:)`.
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    var canSendWriteWithoutResponse: Bool { get }
    
    #if !os(macOS)
    /// A Boolean value that indicates if the remote device has
    /// authorization to receive data over ANCS protocol.
    ///
    /// If this value is false, a user authorization sets this value to
    /// true, which results in a call to the delegate’s
    /// `centralManager(_:didUpdateANCSAuthorizationFor:)` method.
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    var ancsAuthorized: Bool { get }
    #endif
    
    /// Retrieves the current RSSI value for the peripheral while connected
    /// to the central manager.
    ///
    /// On macOS, when you call this method to retrieve the Received Signal
    /// Strength Indicator (RSSI) of the peripheral while connected to the
    /// central manager, the peripheral calls the
    /// `peripheralDidUpdateRSSI(_:error:)` method of its delegate object.
    /// If retrieving the RSSI value of the peripheral succeeds, you can
    /// access it through the peripheral’s rssi property.
    ///
    /// On iOS and tvOS, when you call this method to retrieve the RSSI of
    /// the peripheral while connected to the central manager, the
    /// peripheral calls the `peripheral(_:didReadRSSI:error:)` method of its
    /// delegate object, which includes the RSSI value as a parameter.
    func readRSSI()
    
    /// Discovers the specified services of the peripheral.
    ///
    /// You can provide an array of `CBUUID` objects — representing service
    /// UUIDs — in the `serviceUUIDs` parameter. When you do, the peripheral
    /// returns only the services of the peripheral that match the provided
    /// UUIDs.
    ///
    /// - Note:
    /// If the `servicesUUIDs` parameter is nil, this method returns
    /// all of the peripheral’s available services. This is much
    /// slower than providing an array of service UUIDs to search for.
    ///
    /// When the peripheral discovers one or more services, it
    /// calls the `peripheral(_:didDiscoverServices:):` method of its
    /// delegate object. After a peripheral discovers services, you
    /// can access them through the peripheral’s services property.
    /// - Parameter serviceUUIDs: A list of `CBMUUID` objects
    ///                           representing the service types to be
    ///                           discovered. If `nil`, all services
    ///                           will be discovered.
    func discoverServices(_ serviceUUIDs: [CBMUUID]?)
    
    /// Discovers the specified included services of a
    /// previously-discovered service.
    ///
    /// You can provide an array of CBUUID objects — representing included
    /// service UUIDs — in the includedServiceUUIDs parameter. When you do,
    /// the peripheral returns only the services of the peripheral that
    /// match the provided UUIDs.
    ///
    /// - Note:
    /// If the `servicesUUIDs` parameter is nil, this method returns all of
    /// the peripheral’s available services. This is much slower than
    /// providing an array of service UUIDs to search for.
    ///
    /// When the peripheral discovers one or more included services of the
    /// specified service, it calls the
    /// `peripheral(_:didDiscoverIncludedServicesFor:error:)` method of its
    /// delegate object. After the service discovers its included services,
    /// you can access them through the service’s includedServices property.
    /// - Parameters:
    ///   - includedServiceUUIDs: A list of `CBMUUID` objects
    ///                           representing the included service types
    ///                           to be discovered. If `nil`, all
    ///                           of services included services will
    ///                           be discovered, which is considerably
    ///                           slower and not recommended.
    ///   - service: A GATT service.
    func discoverIncludedServices(_ includedServiceUUIDs: [CBMUUID]?,
                                  for service: CBMService)
    
    /// Discovers the specified characteristics of a service.
    ///
    /// You can provide an array of CBUUID objects—representing
    /// characteristic UUIDs — in the `characteristicUUIDs` parameter. When
    /// you do, the peripheral returns only the characteristics of the
    /// service that match the provided UUIDs. If the `characteristicUUIDs`
    /// parameter is nil, this method returns all characteristics of the service.
    ///
    /// - Note:
    /// If the characteristicUUIDs parameter is nil, this method returns
    /// all of the service’s characteristics. This is much slower than
    /// providing an array of characteristic UUIDs to search for.
    ///
    /// When the peripheral discovers one or more characteristics of the
    /// specified service, it calls the
    /// `peripheral(_:didDiscoverCharacteristicsFor:error:)` method of its
    /// delegate object. After the peripheral discovers the service’s
    /// characteristics, you can access them through the service’s
    /// characteristics property.
    /// - Parameters:
    ///   - characteristicUUIDs: A list of `CBMUUID` objects
    ///                          representing the characteristic types
    ///                          to be discovered. If `nil`, all
    ///                          characteristics of service will
    ///                          be discovered.
    ///   - service: A GATT service.
    func discoverCharacteristics(_ characteristicUUIDs: [CBMUUID]?,
                                 for service: CBMService)
    
    /// Discovers the descriptors of a characteristic.
    ///
    /// When the peripheral discovers one or more descriptors of the
    /// specified characteristic, it calls the
    /// `peripheral(_:didDiscoverDescriptorsFor:error:)` method of its
    /// delegate object. After the peripheral discovers the descriptors of
    /// the characteristic, you can access them through the
    /// characteristic’s descriptors property.
    /// - Parameter characteristic: A GATT characteristic.
    func discoverDescriptors(for characteristic: CBMCharacteristic)
    
    /// Retrieves the value of a specified characteristic.
    ///
    /// When you call this method to read the value of a characteristic,
    /// the peripheral calls the `peripheral(_:didUpdateValueFor:error:)`
    /// method of its delegate object. If the peripheral successfully reads
    /// the value of the characteristic, you can access it through the
    /// characteristic’s value property.
    ///
    /// Not all characteristics have a readable value. You can determine
    /// whether a characteristic’s value is readable by accessing the
    /// relevant properties of the `CBMCharacteristicProperties` enumeration.
    /// - Parameter characteristic: A GATT characteristic.
    func readValue(for characteristic: CBMCharacteristic)
    
    /// Retrieves the value of a specified characteristic descriptor.
    ///
    /// When you call this method to read the value of a characteristic
    /// descriptor, the peripheral calls the
    /// `peripheral(_:didUpdateValueFor:error:)` method of its delegate
    /// object. If the peripheral successfully retrieves the value of the
    /// characteristic descriptor, you can access it through the
    /// characteristic descriptor’s value property.
    /// - Parameter descriptor: A GATT descriptor.
    func readValue(for descriptor: CBMDescriptor)

    /// The maximum amount of data, in bytes, you can send to a
    /// characteristic in a single write type.
    /// - Parameter type: The characteristic write type to inspect.
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBMCharacteristicWriteType) -> Int
    
    /// Writes the value of a characteristic.
    ///
    /// When you call this method to write the value of a characteristic,
    /// the peripheral calls the `peripheral(_:didWriteValueFor:error:)`
    /// method of its delegate object only if you specified the write type
    /// as `CBMCharacteristicWriteType.withResponse`. The response you
    /// receive through the `peripheral(_:didWriteValueFor:error:)`
    /// delegate method indicates whether the write was successful; if the
    /// write failed, it details the cause of the failure in an error.
    ///
    /// On the other hand, if you specify the write type as
    /// `CBCharacteristicWriteType.withoutResponse`, Core Bluetooth
    /// attempts to write the value but doesn’t guarantee success. If the
    /// write doesn’t succeed in this case, you aren’t notified and you
    /// don’t receive an error indicating the cause of the failure.
    ///
    /// Use the `write` and `writeWithoutResponse` members of the
    /// characteristic’s properties enumeration to determine which kinds of
    /// writes you can perform.
    ///
    /// This method copies the data passed into the data parameter, and you
    /// can dispose of it after the method returns.
    /// - Parameters:
    ///   - data: The value to write.
    ///   - characteristic: The characteristic containing the value to write.
    ///   - type: The type of write to execute. For a list of the possible
    ///           types of writes to a characteristic’s value, see
    ///           `CBMCharacteristicWriteType`.
    func writeValue(_ data: Data, for characteristic: CBMCharacteristic,
                    type: CBMCharacteristicWriteType)
    
    /// Writes the value of a characteristic descriptor.
    ///
    /// When you call this method to write the value of a characteristic
    /// descriptor, the peripheral calls the
    /// `peripheral(_:didWriteValueFor:error:)` method of its delegate
    /// object.
    ///
    /// This method copies the data passed into the data parameter, and you
    /// can dispose of it after the method returns.
    ///
    /// You can’t use this method to write the value of a client
    /// configuration descriptor (represented by the
    /// `CBUUIDClientCharacteristicConfigurationString` constant), which
    /// describes the configuration of notification or indications for a
    /// characteristic’s value. If you want to manage notifications or
    /// indications for a characteristic’s value, you must use the
    /// `setNotifyValue(_:for:)` method instead.
    /// - Parameters:
    ///   - data: The value to write.
    ///   - descriptor: The descriptor containing the value to write.
    func writeValue(_ data: Data, for descriptor: CBMDescriptor)

    /// Sets notifications or indications for the value of a specified characteristic.
    ///
    /// When you enable notifications for the characteristic’s value, the
    /// peripheral calls the
    /// `peripheral(_:didUpdateNotificationStateFor:error:)` method of its
    /// delegate object to indicate if the action succeeded. If successful,
    /// the peripheral then calls the
    /// `peripheral(_:didUpdateValueFor:error:)` method of its delegate
    /// object whenever the characteristic value changes. Because the
    /// peripheral chooses when it sends an update, your app should prepare
    /// to handle them as long as notifications or indications remain
    /// enabled. If the specified characteristic’s configuration allows
    /// both notifications and indications, calling this method enables
    /// notifications only. You can disable notifications and indications
    /// for a characteristic’s value by calling this method with the
    /// enabled parameter set to false.
    /// - Parameters:
    ///   - enabled: Boolean value that indicates whether to receive
    ///              notifications or indications whenever the
    ///              characteristic’s value changes. true if you want to
    ///              enable notifications or indications for the
    ///              characteristic’s value. false if you don’t want to
    ///              receive notifications or indications whenever the
    ///              characteristic’s value changes.
    ///   - characteristic: The specified characteristic.
    func setNotifyValue(_ enabled: Bool, for characteristic: CBMCharacteristic)

    /// Attempts to open an L2CAP channel to the peripheral using the
    /// supplied Protocol/Service Multiplexer (PSM).
    /// - Parameter PSM: The PSM of the channel to open.
    #if !os(macOS)
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    func openL2CAPChannel(_ PSM: CBML2CAPPSM)
    #endif
}
