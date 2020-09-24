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

open class CBMService: CBMAttribute {
    internal let identifier: UUID
    private let _uuid: CBMUUID
    
    internal var _includedServices: [CBMService]?
    internal var _characteristics: [CBMCharacteristic]?

    /// A back-pointer to the peripheral this service belongs to.
    open internal(set) unowned var peripheral: CBMPeripheral
    
    /// The type of the service (primary or secondary).
    open fileprivate(set) var isPrimary: Bool
    
    /// The Bluetooth UUID of the attribute.
    open override var uuid: CBMUUID {
        return _uuid
    }
    
    /// A list of included services that have so far been discovered in this service.
    open var includedServices: [CBMService]? {
        return _includedServices
    }

    /// A list of characteristics that have so far been discovered in this service.
    open var characteristics: [CBMCharacteristic]? {
        return _characteristics
    }
    
    /// Returns a service, initialized with a service type and UUID.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the service.
    ///   - isPrimary: The type of the service (primary or secondary).
    init(type uuid: CBMUUID, primary isPrimary: Bool) {
        self.identifier = UUID()
        self.peripheral = uninitializedPeriperheral
        self._uuid = uuid
        self.isPrimary = isPrimary
    }
    
    internal init(shallowCopy service: CBMService,
                  for peripheral: CBMPeripheralMock) {
        self.identifier = service.identifier
        self.peripheral = peripheral
        self._uuid = service._uuid
        self.isPrimary = service.isPrimary
    }
}

internal class CBMServiceNative: CBMService {
    let service: CBService
    
    init(_ service: CBService, in peripheral: CBMPeripheral) {
        self.service = service
        super.init(type: service.uuid, primary: service.isPrimary)
        self.peripheral = peripheral
        self.isPrimary = service.isPrimary
                
        if let nativeCharacteristics = service.characteristics {
            _characteristics = nativeCharacteristics.map { CBMCharacteristicNative($0, in: self) }
        }
        
        if let nativeSecondaryServices = service.includedServices {
            _includedServices = nativeSecondaryServices.map { CBMServiceNative($0, in: peripheral) }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMServiceNative {
            return service == other.service
        }
        return false
    }
    
}

open class CBMServiceMock: CBMService {

    open override var includedServices: [CBMService]? {
        set { _includedServices = newValue }
        get { return _includedServices }
    }

    open override var characteristics: [CBMCharacteristic]? {
        set { _characteristics = newValue }
        get { return _characteristics }
    }
    
    /// Returns a service, initialized with a service type and UUID.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the service.
    ///   - isPrimary: The type of the service (primary or secondary).
    ///   - characteristics: Optional list of characteristics.
    public init(type uuid: CBMUUID, primary isPrimary: Bool,
                characteristics: CBMCharacteristicMock...) {
        super.init(type: uuid, primary: isPrimary)
        self.characteristics = characteristics
    }
    
    open func contains(_ characteristic: CBMCharacteristicMock) -> Bool {
        return _characteristics?.contains(characteristic) ?? false
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMServiceMock {
            return identifier == other.identifier
        }
        return false
    }
}

open class CBMCharacteristic: CBMAttribute {
    internal let identifier: UUID
    private let _uuid: CBMUUID
    
    internal var _descriptors: [CBMDescriptor]?
    
    /// The Bluetooth UUID of the attribute.
    open override var uuid: CBMUUID {
        return _uuid
    }

    /// A back-pointer to the service this characteristic belongs to.
    open internal(set) var service: CBMService
    
    /// The properties of the characteristic.
    public let properties: CBMCharacteristicProperties

    /// The value of the characteristic.
    open internal(set) var value: Data?

    /// A list of the descriptors that have so far been discovered
    /// in this characteristic.
    open var descriptors: [CBMDescriptor]? {
        return _descriptors
    }

    /// Whether the characteristic is currently notifying or not.
    open internal(set) var isNotifying: Bool

    /// Returns an initialized characteristic.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the characteristic.
    ///   - properties: The properties of the characteristic.
    init(type uuid: CBMUUID, properties: CBMCharacteristicProperties) {
        self.identifier = UUID()
        self.service = uninitializedService
        self._uuid = uuid
        self.properties = properties
        self.isNotifying = false
    }
    
    init(shallowCopy characteristic: CBMCharacteristic, in service: CBMService) {
        self.identifier = characteristic.identifier
        self.service = service
        self._uuid = characteristic._uuid
        self.properties = characteristic.properties
        self.isNotifying = false
    }
}

internal class CBMCharacteristicNative: CBMCharacteristic {
    let characteristic: CBCharacteristic
    
    init(_ characteristic: CBCharacteristic, in service: CBMService) {
        self.characteristic = characteristic
        super.init(type: characteristic.uuid, properties: characteristic.properties)
        self.service = service
        self.value = characteristic.value
        self.isNotifying = isNotifying
        
        if let nativeDescriptors = characteristic.descriptors {
            _descriptors = nativeDescriptors.map { CBMDescriptorNative($0, in: self) }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMCharacteristicNative {
            return characteristic == other.characteristic
        }
        return false
    }
}

open class CBMCharacteristicMock: CBMCharacteristic {

    open override var descriptors: [CBMDescriptor]? {
        set {
            _descriptors = newValue
            _descriptors?.forEach { $0.characteristic = self }
        }
        get { return _descriptors }
    }
    
    /// Returns an initialized characteristic.
    /// - Parameters:
    ///   - uuid: The Bluetooth UUID of the characteristic.
    ///   - properties: The properties of the characteristic.
    ///   - descriptors: Optional list of descriptors.
    public init(type uuid: CBMUUID, properties: CBMCharacteristicProperties,
                descriptors: CBMDescriptorMock...) {
        super.init(type: uuid, properties: properties)
        self.descriptors = descriptors
    }
    
    open func contains(_ descriptor: CBMDescriptor) -> Bool {
        return _descriptors?.contains(descriptor) ?? false
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMCharacteristicMock {
            return identifier == other.identifier
        }
        return false
    }
}

open class CBMDescriptor: CBMAttribute {
    internal let identifier: UUID
    private let _uuid: CBMUUID
    
    /// The Bluetooth UUID of the attribute.
    open override var uuid: CBMUUID {
        return _uuid
    }
    
    /// A back-pointer to the characteristic this descriptor belongs to.
    open internal(set) var characteristic: CBMCharacteristic

    /// The value of the descriptor.
    open internal(set) var value: Any?
    
    /// Returns <i>true</i> if the descriptor is a Client Configuration
    /// Characteristic Descriptor (CCCD); otherwise <i>false</i>.
    internal var isCCCD: Bool {
        return uuid.uuidString == "2902"
    }
    
    init(type uuid: CBMUUID) {
        self.identifier = UUID()
        self.characteristic = uninitializedCharacteristic
        self._uuid = uuid
    }
    
    init(shallowCopy descriptor: CBMDescriptor, in characteristic: CBMCharacteristic) {
        self.identifier = descriptor.identifier
        self.characteristic = characteristic
        self._uuid = descriptor._uuid
    }
}

internal class CBMDescriptorNative: CBMDescriptor {
    let descriptor: CBDescriptor
    
    init(_ descriptor: CBDescriptor, in characteristic: CBMCharacteristic) {
        self.descriptor = descriptor
        super.init(type: descriptor.uuid)
        self.characteristic = characteristic
        self.value = descriptor.value
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMDescriptorNative {
            return descriptor == other.descriptor
        }
        return false
    }
}

open class CBMDescriptorMock: CBMDescriptor {
    
    public override init(type uuid: CBMUUID) {
        super.init(type: uuid)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBMDescriptorMock {
            return identifier == other.identifier
        }
        return false
    }
}

open class CBMClientCharacteristicConfigurationDescriptorMock: CBMDescriptorMock {
    
    public init() {
        super.init(type: CBMUUID(string: "2902"))
    }
}

public typealias CBMCCCDescriptorMock = CBMClientCharacteristicConfigurationDescriptorMock

// MARK: - Mocking uninitialized objects

fileprivate let uninitializedPeriperheral   = CBMPeripheralUninitialized()
fileprivate let uninitializedService        = CBMServiceUninitialized()
fileprivate let uninitializedCharacteristic = CBMCharacteristicUninitialized()

fileprivate class CBMPeripheralUninitialized: CBMPeripheral, CustomDebugStringConvertible {
    let debugDescription: String = "<uninitialized>"
    
    var identifier: UUID { uninitialized() }
    var name: String? { uninitialized() }
    var state: CBMPeripheralState { uninitialized() }
    var services: [CBMService]? { uninitialized() }
    var canSendWriteWithoutResponse: Bool { uninitialized() }
    var ancsAuthorized: Bool { uninitialized() }
    var delegate: CBMPeripheralDelegate? {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    func readRSSI() {
        uninitialized()
    }
    
    func discoverServices(_ serviceUUIDs: [CBMUUID]?) {
        uninitialized()
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBMUUID]?,
                                  for service: CBMService) {
        uninitialized()
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBMUUID]?,
                                 for service: CBMService) {
        uninitialized()
    }
    
    func discoverDescriptors(for characteristic: CBMCharacteristic) {
        uninitialized()
    }
    
    func readValue(for characteristic: CBMCharacteristic) {
        uninitialized()
    }
    
    func readValue(for descriptor: CBMDescriptor) {
        uninitialized()
    }
    
    func maximumWriteValueLength(for type: CBMCharacteristicWriteType) -> Int {
        uninitialized()
    }
    
    func writeValue(_ data: Data,
                    for characteristic: CBMCharacteristic,
                    type: CBMCharacteristicWriteType) {
        uninitialized()
    }
    
    func writeValue(_ data: Data, for descriptor: CBMDescriptor) {
        uninitialized()
    }
    
    func setNotifyValue(_ enabled: Bool,
                        for characteristic: CBMCharacteristic) {
        uninitialized()
    }
    
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    func openL2CAPChannel(_ PSM: CBML2CAPPSM) { uninitialized() }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}

fileprivate class CBMServiceUninitialized: CBMService {
    override var debugDescription: String { return "<uninitialized>" }
    override var uuid: CBMUUID { uninitialized() }
    override var characteristics: [CBMCharacteristic]? { uninitialized() }
    override var isPrimary: Bool {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    init() {
        super.init(type: CBMUUID(), primary: true)
    }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}

fileprivate class CBMCharacteristicUninitialized: CBMCharacteristic {
    override var debugDescription: String { return "<uninitialized>" }
    override var uuid: CBMUUID { uninitialized() }
    override var descriptors: [CBMDescriptor]? { uninitialized() }
    override var value: Data? {
        get { uninitialized() }
        set { uninitialized() }
    }
    override var isNotifying: Bool {
        get { uninitialized() }
        set { uninitialized() }
    }
    
    init() {
        super.init(type: CBMUUID(), properties: [])
    }
    
    func uninitialized() -> Never {
        fatalError("Uninitialized")
    }
}
