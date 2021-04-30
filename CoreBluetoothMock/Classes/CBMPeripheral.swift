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
    
    /// The unique, persistent identifier associated with the peer.
    var identifier: UUID { get }
    
    /// The delegate object that will receive peripheral events.
    var delegate: CBMPeripheralDelegate? { get set }
    
    /// The name of the peripheral.
    var name: String? { get }
    
    /// The current connection state of the peripheral.
    var state: CBMPeripheralState { get }
    
    /// A list of `CBMServiceMock` objects that have been
    /// discovered on the peripheral.
    var services: [CBMService]? { get }
    
    /// True if the remote device has space to send a write without
    /// response. If this value is false, the value will be set to
    /// true after the current writes have been flushed, and
    /// `peripheralIsReady(toSendWriteWithoutResponse:)` will be called.
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    var canSendWriteWithoutResponse: Bool { get }
    
    /// True if the remote device has been authorized to receive data
    /// over ANCS (Apple Notification Service Center) protocol.
    /// If this value is false, the value will be set to true after
    /// a user authorization occurs and
    /// `centralManager(_:didUpdateANCSAuthorizationFor:)` will be called.
    #if !os(macOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    var ancsAuthorized: Bool { get }
    #endif
    
    /// While connected, retrieves the current RSSI of the link.
    func readRSSI()
    
    /// Discovers available service(s) on the peripheral.
    /// - Parameter serviceUUIDs: A list of `CBMUUID` objects
    ///                           representing the service types to be
    ///                           discovered. If `nil`, all services
    ///                           will be discovered.
    func discoverServices(_ serviceUUIDs: [CBMUUID]?)
    
    /// Discovers the specified included service(s) of service.
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
    
    /// Discovers the specified characteristic(s) of service.
    /// - Parameters:
    ///   - characteristicUUIDs: A list of `CBMUUID` objects
    ///                          representing the characteristic types
    ///                          to be discovered. If `nil`, all
    ///                          characteristics of service will
    ///                          be discovered.
    ///   - service: A GATT service.
    func discoverCharacteristics(_ characteristicUUIDs: [CBMUUID]?,
                                 for service: CBMService)
    
    /// Discovers the characteristic descriptor(s) of characteristic.
    /// - Parameter characteristic: A GATT characteristic.
    func discoverDescriptors(for characteristic: CBMCharacteristic)
    
    /// Reads the characteristic value for characteristic.
    /// - Parameter characteristic: A GATT characteristic.
    func readValue(for characteristic: CBMCharacteristic)
    
    /// Reads the descriptor value for descriptor.
    /// - Parameter descriptor: A GATT descriptor.
    func readValue(for descriptor: CBMDescriptor)

    /// The maximum amount of data, in bytes, that can be sent to a
    /// characteristic in a single write type.
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBMCharacteristicWriteType) -> Int
    
    /// Writes value to characteristic's characteristic value.
    /// If the `.withResponse` type is specified,
    /// `peripheral(_:didWriteValueForCharacteristic:error:)` is called with the
    /// result of the write request.
    /// If the `.withoutResponse` type is specified, and
    /// `canSendWriteWithoutResponse` is false, the delivery of the data is
    /// best-effort and may not be guaranteed.
    /// - Parameters:
    ///   - data: The value to write.
    ///   - characteristic: The characteristic whose characteristic value will
    ///                     be written.
    ///   - type: The type of write to be executed.
    func writeValue(_ data: Data, for characteristic: CBMCharacteristic,
                    type: CBMCharacteristicWriteType)
    
    /// Writes data to descriptor's value. Client characteristic
    /// configuration descriptors cannot be written using this method, and
    /// should instead use `setNotifyValue(:forCharacteristic:)`.
    /// - Parameters:
    ///   - data: The value to write.
    ///   - descriptor: A GATT characteristic descriptor.
    func writeValue(_ data: Data, for descriptor: CBMDescriptor)

    /// Enables or disables notifications/indications for the characteristic
    /// value of characteristic. If characteristic allows both,
    /// notifications will be used. When notifications/indications are enabled,
    /// updates to the characteristic value will be received via delegate method
    /// `peripheral(:didUpdateValueForCharacteristic:error:)`. Since it is the
    /// peripheral that chooses when to send an update, the application should
    /// be prepared to handle them as long as notifications/indications remain
    /// enabled.
    /// - Parameters:
    ///   - enabled: Whether or not notifications/indications should be enabled.
    ///   - characteristic: The characteristic containing the client
    ///                     characteristic configuration descriptor.
    func setNotifyValue(_ enabled: Bool, for characteristic: CBMCharacteristic)

    /// Attempt to open an L2CAP channel to the peripheral using the supplied PSM.
    /// - Parameter PSM: The PSM of the channel to open.
    #if !os(macOS)
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    func openL2CAPChannel(_ PSM: CBML2CAPPSM)
    #endif
}
