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

public class CBServiceType: CBAttribute {
    internal let identifier: UUID
    private let _uuid: CBUUID
    
    internal var _includedServices: [CBServiceType]?
    internal var _characteristics: [CBCharacteristicType]?

    /// A back-pointer to the peripheral this service belongs to.
    public internal(set) unowned var peripheral: CBPeripheralType
    
    /// The type of the service (primary or secondary).
    public fileprivate(set) var isPrimary: Bool
    
    /// The Bluetooth UUID of the attribute.
    public override var uuid: CBUUID {
        return _uuid
    }
    
    /// A list of included services that have so far been discovered in this service.
    public var includedServices: [CBServiceType]? {
        return _includedServices
    }

    /// A list of characteristics that have so far been discovered in this service.
    public var characteristics: [CBCharacteristicType]? {
        return _characteristics
    }
    
    /// Returns a service, initialized with a service type and UUID.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the service.
    ///   - isPrimary: The type of the service (primary or secondary).
    init(type uuid: CBUUID, primary isPrimary: Bool) {
        self.identifier = UUID()
        self.peripheral = uninitializedPeriperheral
        self._uuid = uuid
        self.isPrimary = isPrimary
    }
    
    internal init(shallowCopy service: CBServiceType) {
        self.identifier = service.identifier
        self.peripheral = service.peripheral
        self._uuid = service._uuid
        self.isPrimary = service.isPrimary
    }
}

internal class CBServiceNative: CBServiceType {
    let service: CBService
    
    init(_ service: CBService, in peripheral: CBPeripheralType) {
        self.service = service
        super.init(type: service.uuid, primary: service.isPrimary)
        self.peripheral = peripheral
        self.isPrimary = service.isPrimary
                
        if let nativeCharacteristics = service.characteristics {
            _characteristics = nativeCharacteristics.map { CBCharacteristicNative($0, in: self) }
        }
        
        if let nativeSecondaryServices = service.includedServices {
            _includedServices = nativeSecondaryServices.map { CBServiceNative($0, in: peripheral) }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBServiceNative {
            return service == other.service
        }
        return false
    }
    
}

public class CBServiceMock: CBServiceType {

    public override var includedServices: [CBServiceType]? {
        set { _includedServices = newValue }
        get { return _includedServices }
    }

    public override var characteristics: [CBCharacteristicType]? {
        set { _characteristics = newValue }
        get { return _characteristics }
    }
    
    public override init(type uuid: CBUUID, primary isPrimary: Bool) {
        super.init(type: uuid, primary: isPrimary)
    }
}

public class CBCharacteristicType: CBAttribute {
    internal let identifier: UUID
    private let _uuid: CBUUID
    
    internal var _descriptors: [CBDescriptorType]?
    
    /// The Bluetooth UUID of the attribute.
    public override var uuid: CBUUID {
        return _uuid
    }

    /// A back-pointer to the service this characteristic belongs to.
    public internal(set) var service: CBServiceType
    
    /// The properties of the characteristic.
    public let properties: CBCharacteristicProperties

    /// The value of the characteristic.
    public internal(set) var value: Data?

    /// A list of the descriptors that have so far been discovered
    /// in this characteristic.
    public var descriptors: [CBDescriptorType]? {
        return _descriptors
    }

    /// Whether the characteristic is currently notifying or not.
    public internal(set) var isNotifying: Bool

    /// Returns an initialized characteristic.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the characteristic.
    ///   - properties: The properties of the characteristic.
    init(type uuid: CBUUID, properties: CBCharacteristicProperties) {
        self.identifier = UUID()
        self.service = uninitializedService
        self._uuid = uuid
        self.properties = properties
        self.isNotifying = false
    }
    
    init(shallowCopy characteristic: CBCharacteristicType, in service: CBServiceType) {
        self.identifier = characteristic.identifier
        self.service = service
        self._uuid = characteristic._uuid
        self.properties = characteristic.properties
        self.isNotifying = false
    }
}

internal class CBCharacteristicNative: CBCharacteristicType {
    let characteristic: CBCharacteristic
    
    init(_ characteristic: CBCharacteristic, in service: CBServiceType) {
        self.characteristic = characteristic
        super.init(type: characteristic.uuid, properties: characteristic.properties)
        self.service = service
        self.value = characteristic.value
        self.isNotifying = isNotifying
        
        if let nativeDescriptors = characteristic.descriptors {
            _descriptors = nativeDescriptors.map { CBDescriptorNative($0, in: self) }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBCharacteristicNative {
            return characteristic == other.characteristic
        }
        return false
    }
}

public class CBCharacteristicMock: CBCharacteristicType {

    public override var descriptors: [CBDescriptorType]? {
        set {
            _descriptors = newValue
            _descriptors?.forEach { $0.characteristic = self }
        }
        get { return _descriptors }
    }
    
    public override init(type uuid: CBUUID, properties: CBCharacteristicProperties) {
        super.init(type: uuid, properties: properties)
    }
}

public class CBDescriptorType: CBAttribute {
    internal let identifier: UUID
    private let _uuid: CBUUID
    
    /// The Bluetooth UUID of the attribute.
    public override var uuid: CBUUID {
        return _uuid
    }
    
    /// A back-pointer to the characteristic this descriptor belongs to.
    public internal(set) var characteristic: CBCharacteristicType

    /// The value of the descriptor.
    public internal(set) var value: Any?
    
    init(type uuid: CBUUID) {
        self.identifier = UUID()
        self.characteristic = uninitializedCharacteristic
        self._uuid = uuid
    }
    
    init(shallowCopy descriptor: CBDescriptorType, in characteristic: CBCharacteristicType) {
        self.identifier = descriptor.identifier
        self.characteristic = characteristic
        self._uuid = descriptor._uuid
    }
}

internal class CBDescriptorNative: CBDescriptorType {
    let descriptor: CBDescriptor
    
    init(_ descriptor: CBDescriptor, in characteristic: CBCharacteristicType) {
        self.descriptor = descriptor
        super.init(type: descriptor.uuid)
        self.characteristic = characteristic
        self.value = descriptor.value
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBDescriptorNative {
            return descriptor == other.descriptor
        }
        return false
    }
}

public class CBDescriptorMock: CBDescriptorType {
    
    public override init(type uuid: CBUUID) {
        super.init(type: uuid)
    }
}

public class CBClientCharacteristicConfigurationDescriptorMock: CBDescriptorType {
    
    public init() {
        super.init(type: CBUUID(string: "2902"))
    }
}

// MARK: - Mocking uninitialized objects

fileprivate let uninitializedPeriperheral = CBPeripheralUninitialized()
fileprivate let uninitializedService = CBServiceUninitialized()
fileprivate let uninitializedCharacteristic = CBCharacteristicUninitialized()

fileprivate class CBPeripheralUninitialized: CBPeripheralType, CustomDebugStringConvertible {
    let debugDescription: String = "<uninitialized>"
    
    var identifier: UUID { uninitialized() }
    var name: String? { uninitialized() }
    var state: CBPeripheralState { uninitialized() }
    var services: [CBServiceType]? { uninitialized() }
    var canSendWriteWithoutResponse: Bool { uninitialized() }
    var ancsAuthorized: Bool { uninitialized() }
    var delegate: CBPeripheralDelegateType? {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        uninitialized()
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?,
                                  for service: CBServiceType) {
        uninitialized()
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?,
                                 for service: CBServiceType) {
        uninitialized()
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristicType) {
        uninitialized()
    }
    
    func readValue(for characteristic: CBCharacteristicType) {
        uninitialized()
    }
    
    func readValue(for descriptor: CBDescriptorType) {
        uninitialized()
    }
    
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        uninitialized()
    }
    
    func writeValue(_ data: Data,
                    for characteristic: CBCharacteristicType,
                    type: CBCharacteristicWriteType) {
        uninitialized()
    }
    
    func writeValue(_ data: Data, for descriptor: CBDescriptorType) {
        uninitialized()
    }
    
    func setNotifyValue(_ enabled: Bool,
                        for characteristic: CBCharacteristicType) {
        uninitialized()
    }
    
    func openL2CAPChannel(_ PSM: CBL2CAPPSM) { uninitialized() }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}

fileprivate class CBServiceUninitialized: CBServiceType {
    override var debugDescription: String { return "<uninitialized>" }
    override var uuid: CBUUID { uninitialized() }
    override var characteristics: [CBCharacteristicType]? { uninitialized() }
    override var isPrimary: Bool {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    init() {
        super.init(type: CBUUID(), primary: true)
    }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}

fileprivate class CBCharacteristicUninitialized: CBCharacteristicType {
    override var debugDescription: String { return "<uninitialized>" }
    override var uuid: CBUUID { uninitialized() }    
    override var descriptors: [CBDescriptorType]? { uninitialized() }
    override var value: Data? {
        get { uninitialized() }
        set { uninitialized() }
    }
    override var isNotifying: Bool {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    init() {
        super.init(type: CBUUID(), properties: [])
    }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}
