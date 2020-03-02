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

public class CBMCentralManagerNative: NSObject, CBMCentralManager {
    public weak var delegate: CBMCentralManagerDelegate?
    
    private var manager: CBCentralManager!
    private var wrapper: CBCentralManagerDelegate!
    private var peripherals: [UUID : CBMPeripheralNative] = [:]
    
    private class CBMCentralManagerDelegateWrapper: NSObject, CBCentralManagerDelegate {
        fileprivate var manager: CBMCentralManagerNative
        
        init(_ manager: CBMCentralManagerNative) {
            self.manager = manager
        }
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            manager.delegate?.centralManagerDidUpdateState(manager)
        }
        
        // This methods is moved to a separate class below. Otherwise a warning
        // is generated when setting delegate to the CBCentralManager when
        // restoration was not enabled.
        //
        // func centralManager(_ central: CBCentralManager,
        //                     willRestoreState dict: [String : Any]) {
        //     manager.delegate?.centralManager(manager, willRestoreState: dict)
        // }
        
        func centralManager(_ central: CBCentralManager,
                            didDiscover peripheral: CBPeripheral,
                            advertisementData: [String : Any],
                            rssi RSSI: NSNumber) {
            manager.delegate?.centralManager(manager,
                                             didDiscover: getPeripheral(peripheral),
                                             advertisementData: advertisementData,
                                             rssi: RSSI)
        }
        
        func centralManager(_ central: CBCentralManager,
                            didConnect peripheral: CBPeripheral) {
            manager.delegate?.centralManager(manager,
                                             didConnect: getPeripheral(peripheral))
        }
        
        func centralManager(_ central: CBCentralManager,
                            didFailToConnect peripheral: CBPeripheral,
                            error: Error?) {
            manager.delegate?.centralManager(manager,
                                             didFailToConnect: getPeripheral(peripheral),
                                             error: error)
        }
        
        func centralManager(_ central: CBCentralManager,
                            didDisconnectPeripheral peripheral: CBPeripheral,
                            error: Error?) {
            manager.delegate?.centralManager(manager,
                                             didDisconnectPeripheral: getPeripheral(peripheral),
                                             error: error)
        }
        
        @available(iOS 13.0, *)
        func centralManager(_ central: CBCentralManager,
                            didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
            manager.delegate?.centralManager(manager,
                                             didUpdateANCSAuthorizationFor: getPeripheral(peripheral))
        }
        
        @available(iOS 13.0, *)
        func centralManager(_ central: CBCentralManager,
                            connectionEventDidOccur event: CBConnectionEvent,
                            for peripheral: CBPeripheral) {
            manager.delegate?.centralManager(manager,
                                             connectionEventDidOccur: event,
                                             for: getPeripheral(peripheral))
        }
        
        private func getPeripheral(_ peripheral: CBPeripheral) -> CBMPeripheralNative {
            return manager.peripherals[peripheral.identifier] ?? newPeripheral(peripheral)
        }
        
        private func newPeripheral(_ peripheral: CBPeripheral) -> CBMPeripheralNative {
            let p = CBMPeripheralNative(peripheral)
            manager.peripherals[peripheral.identifier] = p
            return p
        }
    }
    
    private class CBMCentralManagerDelegateWrapperWithRestoration: CBMCentralManagerDelegateWrapper {
        
        override init(_ manager: CBMCentralManagerNative) {
            super.init(manager)
        }
        
        func centralManager(_ central: CBCentralManager,
                            willRestoreState dict: [String : Any]) {
            manager.delegate?.centralManager(manager, willRestoreState: dict)
        }
    }
    
    public var state: CBMManagerState {
        return CBMManagerState(rawValue: manager.state.rawValue) ?? .unknown
    }
    
    @available(iOS 9.0, *)
    public var isScanning: Bool {
        return manager.isScanning
    }
    
    @available(iOS 13.0, *)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        return CBCentralManager.supports(features)
    }
    
    public override init() {
        super.init()
        self.wrapper = CBMCentralManagerDelegateWrapper(self)
        self.manager = CBCentralManager()
        self.manager.delegate = wrapper
    }
    
    public init(delegate: CBMCentralManagerDelegate?, queue: DispatchQueue?) {
        super.init()
        self.wrapper = CBMCentralManagerDelegateWrapper(self)
        self.manager = CBCentralManager(delegate: wrapper, queue: queue)
        self.delegate = delegate
    }
    
    @available(iOS 7.0, *)
    public init(delegate: CBMCentralManagerDelegate?, queue: DispatchQueue?,
                options: [String : Any]?) {
        super.init()
        let restoration = options?[CBCentralManagerOptionRestoreIdentifierKey] != nil
        self.wrapper = restoration ?
            CBMCentralManagerDelegateWrapperWithRestoration(self) :
            CBMCentralManagerDelegateWrapper(self)
        self.manager = CBCentralManager(delegate: wrapper, queue: queue, options: options)
        self.delegate = delegate
    }
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?,
                                   options: [String : Any]?) {
        manager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
    
    public func stopScan() {
        manager.stopScan()
    }
    
    public func connect(_ peripheral: CBMPeripheral, options: [String : Any]?) {
        if let peripheral = peripherals[peripheral.identifier] {
            manager.connect(peripheral.peripheral, options: options)
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBMPeripheral) {
        if let peripheral = peripherals[peripheral.identifier] {
            manager.cancelPeripheralConnection(peripheral.peripheral)
        }
    }
    
    @available(iOS 7.0, *)
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBMPeripheral] {
        let retrievedPeripherals = manager.retrievePeripherals(withIdentifiers: identifiers)
        retrievedPeripherals
            .filter { peripherals[$0.identifier] == nil }
            .forEach { peripherals[$0.identifier] = CBMPeripheralNative($0) }
        return peripherals
            .filter { identifiers.contains($0.key) }
            .map { $0.value }
    }
    
    @available(iOS 7.0, *)
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBMPeripheral] {
        let retrievedPeripherals = manager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        retrievedPeripherals
            .filter { peripherals[$0.identifier] == nil }
            .forEach { peripherals[$0.identifier] = CBMPeripheralNative($0) }
        return peripherals
            .filter { entry in retrievedPeripherals.contains(where: { $0.identifier == entry.key }) }
            .map { $0.value }
    }
    
    @available(iOS 13.0, *)
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil) {
        manager.registerForConnectionEvents(options: options)
    }
}

public class CBMPeripheralNative: CBPeer, CBMPeripheral {
    
    private class CBPeripheralDelegateWrapper: NSObject, CBPeripheralDelegate {
        private var impl: CBMPeripheralNative
        
        init(_ peripheral: CBMPeripheralNative) {
            self.impl = peripheral
        }
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            impl.delegate?.peripheralDidUpdateName(impl)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverServices error: Error?) {
            smartCopy(peripheral.services)
            impl.delegate?.peripheral(impl, didDiscoverServices: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverIncludedServicesFor service: CBService,
                        error: Error?) {
            smartCopy(peripheral.services)
            usingMock(of: service) { peripheral, delegate, service in
                delegate.peripheral(peripheral,
                                    didDiscoverIncludedServicesFor: service,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverCharacteristicsFor service: CBService,
                        error: Error?) {
            smartCopy(peripheral.services)
            usingMock(of: service) { peripheral, delegate, service in
                delegate.peripheral(peripheral,
                                    didDiscoverCharacteristicsFor: service,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                        error: Error?) {
            smartCopy(peripheral.services)
            usingMock(of: characteristic) { peripheral, delegate, characteristic in
                delegate.peripheral(peripheral,
                                    didDiscoverDescriptorsFor: characteristic,
                                    error: error)
            }
        }

        @available(iOS 7.0, *)
        func peripheral(_ peripheral: CBPeripheral,
                        didModifyServices invalidatedServices: [CBService]) {
            var invalidatedServiceMocks: [CBMService] = []
            invalidatedServices.forEach { service in
                if let services = impl.mockServices,
                   let index = services
                    .firstIndex(where: { $0.service == service}) {
                    invalidatedServiceMocks.append(services[index])
                    impl.mockServices?.remove(at: index)
                }
            }
            impl.delegate?.peripheral(impl, didModifyServices: invalidatedServiceMocks)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateNotificationStateFor characteristic: CBCharacteristic,
                        error: Error?) {
            usingMock(of: characteristic) { peripheral, delegate, mock in
                mock.isNotifying = characteristic.isNotifying
                delegate.peripheral(peripheral,
                                    didUpdateNotificationStateFor: mock,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didWriteValueFor characteristic: CBCharacteristic,
                        error: Error?) {
            usingMock(of: characteristic) { peripheral, delegate, characteristic in
                delegate.peripheral(peripheral,
                                    didWriteValueFor: characteristic,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didWriteValueFor descriptor: CBDescriptor,
                        error: Error?) {
            usingMock(of: descriptor) { peripheral, delegate, descriptor in
                delegate.peripheral(peripheral,
                                    didWriteValueFor: descriptor,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor characteristic: CBCharacteristic,
                        error: Error?) {
            usingMock(of: characteristic) { peripheral, delegate, mockCharacteristic in
                mockCharacteristic.value = characteristic.value
                delegate.peripheral(peripheral,
                                    didUpdateValueFor: mockCharacteristic,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor descriptor: CBDescriptor,
                        error: Error?) {
            usingMock(of: descriptor) { peripheral, delegate, mockDescriptor in
                mockDescriptor.value = descriptor.value
                delegate.peripheral(peripheral,
                                    didUpdateValueFor: mockDescriptor,
                                    error: error)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didReadRSSI RSSI: NSNumber,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didReadRSSI: RSSI, error: error)
        }

        func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
            if #available(iOS 11.0, *) {
                impl.delegate?.peripheralIsReady(toSendWriteWithoutResponse: impl)
            }
        }
        
        @available(iOS 11.0, *)
        func peripheral(_ peripheral: CBPeripheral,
                        didOpen channel: CBL2CAPChannel?,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didOpen: channel, error: error)
        }
        
        /// Updates the local list of serivces with received ones.
        /// - Parameter services: New list of services.
        private func smartCopy(_ services: [CBService]?) {
            guard let services = services else {
                return
            }
            // So far the "smart" copy isn't that smart and just replaces
            // all old references with new ones. The old should still work,
            // as they have the correct native references and isEqual also
            // compares them. But ideally, the copy should only add new
            // attributes, without replacing any existing.
            // TODO: Implement smart copy of services.
            impl.mockServices = services.map { CBMServiceNative($0, in: impl) }            
        }
        
        /// Returns the wrapper for the native CBService.
        /// - Parameter service: The native service.
        private func mock(of service: CBService) -> CBMServiceNative? {
            return impl.mockServices?.first { $0.service == service }
        }
        
        /// Returns the wrapper for the native CBCharacteristic.
        /// - Parameter characteristic: The native characteristic.
        private func mock(of characteristic: CBCharacteristic) -> CBMCharacteristicNative? {
            let service = mock(of: characteristic.service)
            return (service?._characteristics as? [CBMCharacteristicNative])?
                .first { $0.characteristic == characteristic }
        }
        
        /// Returns the wrapper for the native CBDescriptor.
        /// - Parameter descriptor: The native descriptor.
        private func mock(of descriptor: CBDescriptor) -> CBMDescriptorNative? {
            let characteristic = mock(of: descriptor.characteristic)
            return (characteristic?._descriptors as? [CBMDescriptorNative])?
                .first { $0.descriptor == descriptor }
        }
        
        /// Calls the action with mock service.
        /// - Parameters:
        ///   - service: The native service.
        ///   - action: The action to perform on its mock.
        private func usingMock(of service: CBService,
                               action: @escaping (CBMPeripheral, CBMPeripheralDelegate, CBMService) -> ()) {
            if let delegate = impl.delegate,
               let serviceMock = mock(of: service) {
                action(impl, delegate, serviceMock)
            }
        }
        
        /// Calls the action with mock characteristic.
        /// - Parameters:
        ///   - service: The native characteristic.
        ///   - action: The action to perform on its mock.
        private func usingMock(of characteristic: CBCharacteristic,
                               action: @escaping (CBMPeripheral, CBMPeripheralDelegate, CBMCharacteristic) -> ()) {
            usingMock(of: characteristic.service) { p, d, s in
                if let characteristicMock = self.mock(of: characteristic) {
                    action(p, d, characteristicMock)
                }
            }
        }
        
        /// Calls the action with mock descriptor.
        /// - Parameters:
        ///   - service: The native descriptor.
        ///   - action: The action to perform on its mock.
        private func usingMock(of descriptor: CBDescriptor,
                               action: @escaping (CBMPeripheral, CBMPeripheralDelegate, CBMDescriptor) -> ()) {
            usingMock(of: descriptor.characteristic) { p, d, c in
                if let descriptorMock = self.mock(of: descriptor) {
                    action(p, d, descriptorMock)
                }
            }
        }
    }
    
    private var wrapper: CBPeripheralDelegate?
    public weak var delegate: CBMPeripheralDelegate? {
        didSet {
            if let _ = delegate {
                // We need to hold a strong reference to the wrapper, otherwise
                // it would be immediately deallocated.
                wrapper = CBPeripheralDelegateWrapper(self)
                peripheral.delegate = wrapper
            } else {
                wrapper = nil
                peripheral.delegate = nil
            }
        }
    }
    
    /// The unique, persistent identifier associated with the peer.
    public override var identifier: UUID {
        return peripheral.identifier
    }
    
    public var name: String? {
        return peripheral.name
    }
    
    public var state: CBPeripheralState {
        return peripheral.state
    }
    
    private var mockServices: [CBMServiceNative]?
    public var services: [CBMService]? {
        return mockServices
    }
    
    @available(iOS 11.0, *)
    public var canSendWriteWithoutResponse: Bool {
        return peripheral.canSendWriteWithoutResponse
    }
    
    @available(iOS 13.0, *)
    public var ancsAuthorized: Bool {
        return peripheral.ancsAuthorized
    }
    
    fileprivate let peripheral: CBPeripheral
    
    fileprivate init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
    
    public func readRSSI() {
        peripheral.readRSSI()
    }
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?,
                                         for service: CBMService) {
        if let n = service as? CBMServiceNative {
            peripheral.discoverIncludedServices(includedServiceUUIDs, for: n.service)
        }
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?,
                                        for service: CBMService) {
        if let n = service as? CBMServiceNative {
            peripheral.discoverCharacteristics(characteristicUUIDs, for: n.service)
        }
    }
    
    public func discoverDescriptors(for characteristic: CBMCharacteristic) {
        if let n = characteristic as? CBMCharacteristicNative {
            peripheral.discoverDescriptors(for: n.characteristic)
        }
    }
    
    public func readValue(for characteristic: CBMCharacteristic) {
        if let n = characteristic as? CBMCharacteristicNative {
            peripheral.readValue(for: n.characteristic)
        }
    }
    
    public func readValue(for descriptor: CBMDescriptor) {
        if let n = descriptor as? CBMDescriptorNative {
            peripheral.readValue(for: n.descriptor)
        }
    }
    
    @available(iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }
    
    public func writeValue(_ data: Data, for characteristic: CBMCharacteristic,
                           type: CBCharacteristicWriteType) {
        if let n = characteristic as? CBMCharacteristicNative {
            peripheral.writeValue(data, for: n.characteristic, type: type)
        }
    }
    
    public func writeValue(_ data: Data, for descriptor: CBMDescriptor) {
        if let n = descriptor as? CBMDescriptorNative {
            peripheral.writeValue(data, for: n.descriptor)
        }
    }
    
    public func setNotifyValue(_ enabled: Bool,
                               for characteristic: CBMCharacteristic) {
        if let n = characteristic as? CBMCharacteristicNative {
            peripheral.setNotifyValue(enabled, for: n.characteristic)
        }
    }
    
    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        peripheral.openL2CAPChannel(PSM)
    }
    
    public override var hash: Int {
        return identifier.hashValue
    }
}
