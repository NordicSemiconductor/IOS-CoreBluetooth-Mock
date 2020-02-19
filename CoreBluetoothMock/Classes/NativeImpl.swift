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

public class CBCentralManagerNative: CBCentralManagerType {
    // The mock delegate is not used in the native implementation.
    public weak var mockDelegate: CBCentralManagerMockDelegate? {
        didSet {
            mockDelegate = nil
        }
    }
    
    private let manager: CBCentralManager
    private var peripherals: [UUID : CBPeripheralNative] = [:]
    
    private class CBCentralManagerDelegateWrapper: NSObject, CBCentralManagerDelegate {
        private var manager: CBCentralManagerNative
        
        init(_ manager: CBCentralManagerNative) {
            self.manager = manager
        }
        
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            manager.delegate?.centralManagerDidUpdateState(manager)
        }
        
        func centralManager(_ central: CBCentralManager,
                            willRestoreState dict: [String : Any]) {
            manager.delegate?.centralManager(manager, willRestoreState: dict)
        }
        
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
            manager.delegate?.centralManager(manager, didConnect: getPeripheral(peripheral))
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
        
        private func getPeripheral(_ peripheral: CBPeripheral) -> CBPeripheralNative {
            return manager.peripherals[peripheral.identifier] ?? newPeripheral(peripheral)
        }
        
        private func newPeripheral(_ peripheral: CBPeripheral) -> CBPeripheralNative {
            let p = CBPeripheralNative(peripheral)
            manager.peripherals[peripheral.identifier] = p
            return p
        }
    }
    
    private var wrapper: CBCentralManagerDelegate?
    public weak var delegate: CBCentralManagerDelegateType? {
        didSet {
            if let _ = delegate {
                // We need to hold a strong reference to the wrapper, otherwise
                // it would be immediately deallocated.
                wrapper = CBCentralManagerDelegateWrapper(self)
                manager.delegate = wrapper
            } else {
                wrapper = nil
                manager.delegate = nil
            }
        }
    }
    
    public var state: CBManagerStateType {
        return CBManagerStateType(rawValue: manager.state.rawValue) ?? .unknown
    }
    
    @available(iOS 9.0, *)
    public var isScanning: Bool {
        return manager.isScanning
    }
    
    @available(iOS 13.0, *)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        return CBCentralManager.supports(features)
    }
    
    public init() {
        self.manager = CBCentralManager()
    }
    
    public init(delegate: CBCentralManagerDelegateType?, queue: DispatchQueue?) {
        self.manager = CBCentralManager(delegate: nil, queue: queue)
        self.delegate = delegate
    }
    
    @available(iOS 7.0, *)
    public init(delegate: CBCentralManagerDelegateType?, queue: DispatchQueue?,
                options: [String : Any]?) {
        self.manager = CBCentralManager(delegate: nil, queue: queue, options: options)
        self.delegate = delegate
    }
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?,
                                   options: [String : Any]?) {
        manager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
    
    public func stopScan() {
        manager.stopScan()
    }
    
    public func connect(_ peripheral: CBPeripheralType, options: [String : Any]?) {
        if let peripheral = peripherals[peripheral.identifier] {
            manager.connect(peripheral.peripheral, options: options)
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        if let peripheral = peripherals[peripheral.identifier] {
            manager.cancelPeripheralConnection(peripheral.peripheral)
        }
    }
    
    @available(iOS 7.0, *)
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralType] {
        let retrievedPeripherals = manager.retrievePeripherals(withIdentifiers: identifiers)
        retrievedPeripherals
            .filter { peripherals[$0.identifier] == nil }
            .forEach { peripherals[$0.identifier] = CBPeripheralNative($0) }
        return peripherals
            .filter { identifiers.contains($0.key) }
            .map { $0.value }
    }
    
    @available(iOS 7.0, *)
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralType] {
        let retrievedPeripherals = manager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        retrievedPeripherals
            .filter { peripherals[$0.identifier] == nil }
            .forEach { peripherals[$0.identifier] = CBPeripheralNative($0) }
        return peripherals
            .filter { entry in retrievedPeripherals.contains(where: { $0.identifier == entry.key }) }
            .map { $0.value }
    }
    
    @available(iOS 13.0, *)
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil) {
        manager.registerForConnectionEvents(options: options)
    }
}

public class CBPeripheralNative: CBPeer, CBPeripheralType {
    
    private class CBPeripheralDelegateWrapper: NSObject, CBPeripheralDelegate {
        private var impl: CBPeripheralNative
        
        init(_ peripheral: CBPeripheralNative) {
            self.impl = peripheral
        }
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            impl.delegate?.peripheralDidUpdateName(impl)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverServices error: Error?) {
            impl.delegate?.peripheral(impl, didDiscoverServices: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverIncludedServicesFor service: CBService,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didDiscoverIncludedServicesFor: service,
                                      error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverCharacteristicsFor service: CBService,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didDiscoverCharacteristicsFor: service,
                                      error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didDiscoverDescriptorsFor: characteristic,
                                      error: error)
        }

        @available(iOS 7.0, *)
        func peripheral(_ peripheral: CBPeripheral,
                        didModifyServices invalidatedServices: [CBService]) {
            impl.delegate?.peripheral(impl, didModifyServices: invalidatedServices)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateNotificationStateFor characteristic: CBCharacteristic,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didUpdateNotificationStateFor: characteristic,
                                      error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didWriteValueFor characteristic: CBCharacteristic,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didWriteValueFor: characteristic, error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didWriteValueFor descriptor: CBDescriptor,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didWriteValueFor: descriptor, error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor characteristic: CBCharacteristic,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didUpdateValueFor: characteristic, error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor descriptor: CBDescriptor,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didUpdateValueFor: descriptor, error: error)
        }
        
        func peripheral(_ peripheral: CBPeripheral,
                        didReadRSSI RSSI: NSNumber,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didReadRSSI: RSSI, error: error)
        }
        
        func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
            impl.delegate?.peripheralIsReady(toSendWriteWithoutResponse: impl)
        }
        
        @available(iOS 11.0, *)
        func peripheral(_ peripheral: CBPeripheral,
                        didOpen channel: CBL2CAPChannel?,
                        error: Error?) {
            impl.delegate?.peripheral(impl, didOpen: channel, error: error)
        }
    }
    
    private var wrapper: CBPeripheralDelegate?
    public weak var delegate: CBPeripheralDelegateType? {
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
    
    public var services: [CBService]? {
        return peripheral.services
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
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?,
                                        for service: CBService) {
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    public func discoverDescriptors(for characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    public func readValue(for characteristic: CBCharacteristic) {
        peripheral.readValue(for: characteristic)
    }
    
    public func readValue(for descriptor: CBDescriptor) {
        peripheral.readValue(for: descriptor)
    }
    
    @available(iOS 9.0, *)
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        return peripheral.maximumWriteValueLength(for: type)
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    public func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        peripheral.writeValue(data, for: descriptor)
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic)
    }
    
    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        peripheral.openL2CAPChannel(PSM)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? CBPeripheralNative {
            return identifier == other.identifier
        }
        return false
    }
    
    public override var hash: Int {
        return identifier.hashValue
    }
}
