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

public protocol CBPeripheralType: class {
    
    /// The unique, persistent identifier associated with the peer.
    var identifier: UUID { get }
    
    /// The delegate object that will receive peripheral events.
    var delegate: CBPeripheralDelegateType? { get set }
    
    /// The name of the peripheral.
    var name: String? { get }
    
    /// The current connection state of the peripheral.
    var state: CBPeripheralState { get }
    
    /// A list of <code>CBServiceMock</code> objects that have been
    /// discovered on the peripheral.
    var services: [CBServiceType]? { get }
    
    /// True if the remote device has space to send a write without
    /// response. If this value is false, the value will be set to
    /// true after the current writes have been flushed, and
    /// `peripheralIsReady(toSendWriteWithoutResponse:)` will be called.
    @available(iOS 11.0, *)
    var canSendWriteWithoutResponse: Bool { get }
    
    /// True if the remote device has been authorized to receive data
    /// over ANCS (Apple Notification Service Center) protocol.
    /// If this value is false, the value will be set to true after
    /// a user authorization occurs and
    /// `centralManager(_:didUpdateANCSAuthorizationFor:)` will be called.
    @available(iOS 13.0, *)
    var ancsAuthorized: Bool { get }
    
    /// Discovers available service(s) on the peripheral.
    /// - Parameter serviceUUIDs: A list of <code>CBUUID</code> objects
    ///                           representing the service types to be
    ///                           discovered. If <i>nil</i>, all services
    ///                           will be discovered.
    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    
    /// Discovers the specified included service(s) of <i>service</i>.
    /// - Parameters:
    ///   - includedServiceUUIDs: A list of <code>CBUUID</code> objects
    ///                           representing the included service types
    ///                           to be discovered. If <i>nil</i>, all
    ///                           of <i>service</i>s included services will
    ///                           be discovered, which is considerably
    ///                           slower and not recommended.
    ///   - service: A GATT service.
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?,
                                  for service: CBServiceType)
    
    /// Discovers the specified characteristic(s) of <i>service</i>.
    /// - Parameters:
    ///   - characteristicUUIDs: A list of <code>CBUUID</code> objects
    ///                          representing the characteristic types
    ///                          to be discovered. If <i>nil</i>, all
    ///                          characteristics of <i>service</i> will
    ///                          be discovered.
    ///   - service: A GATT service.
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?,
                                 for service: CBServiceType)
    
    /// Discovers the characteristic descriptor(s) of <i>characteristic</i>.
    /// - Parameter characteristic: A GATT characteristic.
    func discoverDescriptors(for characteristic: CBCharacteristicType)
    
    /// Reads the characteristic value for <i>characteristic</i>.
    /// - Parameter characteristic: A GATT characteristic.
    func readValue(for characteristic: CBCharacteristicType)
    
    /// Reads the descriptor value for <i>descriptor</i>.
    /// - Parameter descriptor: A GATT descriptor.
    func readValue(for descriptor: CBDescriptorType)

    /// The maximum amount of data, in bytes, that can be sent to a
    /// characteristic in a single write type.
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    
    /// Writes <i>value</i> to <i>characteristic</i>'s characteristic value.
    /// If the <code>CBCharacteristicWriteWithResponse</code> type is specified,
    /// `peripheral(_:didWriteValueForCharacteristic:error:)` is called with the
    /// result of the write request.
    /// If the <code>CBCharacteristicWriteWithoutResponse</code> type is
    /// specified, and `canSendWriteWithoutResponse` is false, the delivery
    /// of the data is best-effort and may not be guaranteed.
    /// - Parameters:
    ///   - data: The value to write.
    ///   - characteristic: The characteristic whose characteristic value will
    ///                     be written.
    ///   - type: The type of write to be executed.
    func writeValue(_ data: Data, for characteristic: CBCharacteristicType,
                    type: CBCharacteristicWriteType)
    
    /// Writes <i>data</i> to <i>descriptor</i>'s value. Client characteristic
    /// configuration descriptors cannot be written using this method, and
    /// should instead use `setNotifyValue(:forCharacteristic:).
    /// - Parameters:
    ///   - data: The value to write.
    ///   - descriptor: A GATT characteristic descriptor.
    func writeValue(_ data: Data, for descriptor: CBDescriptorType)

    /// Enables or disables notifications/indications for the characteristic
    /// value of <i>characteristic</i>. If <i>characteristic</i> allows both,
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
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristicType)

    @available(iOS 11.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
}
