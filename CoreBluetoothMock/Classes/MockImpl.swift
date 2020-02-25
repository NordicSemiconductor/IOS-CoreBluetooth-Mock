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

public class CBCentralManagerMock: CBCentralManagerType {
    public var delegate: CBCentralManagerDelegateType?
    
    /// A list of all mock managers instantiated by user.
    private static var managers: [WeakRef<CBCentralManagerMock>] = []
    /// A list of peripherals known to the system.
    private static var mockPeripherals: [MockPeripheral] = []
    
    /// The global state of the Bluetooth adapter on the device.
    internal static var managerState: CBManagerStateType = .poweredOff {
        didSet {
            // For all existing managers...
            managers.forEach { weakRef in
                if let manager = weakRef.ref {
                    // ...stop scanning. If state changed to .poweredOn, scanning
                    // must have been stopped before.
                    if managerState != .poweredOn {
                        manager.stopScan()
                    }
                    // ...and notify delegate.
                    manager.queue.async {
                        manager.delegate?.centralManagerDidUpdateState(manager)
                    }
                }
            }
            // Compact the list, if any of managers were disposed.
            managers.removeAll { $0.ref == nil }
        }
    }
    
    public var state: CBManagerStateType {
        return initialized ? CBCentralManagerMock.managerState : .unknown
    }
    public fileprivate(set) var isScanning: Bool

    private let rssiDeviation = 15 // dBm
    /// The dispatch queue used for all callbacks.
    fileprivate let queue: DispatchQueue
    /// Active timers reporting scan results.
    private var scanTimers: [Timer] = []
    /// A map of peripherals known to this central manager.
    private var peripherals: [UUID : CBPeripheralMock] = [:]
    /// A flag set to true few milliseconds after the manager is created.
    /// Some features, like the state or retrieving peripherals are not
    /// available when manager hasn't been initialized yet.
    private var initialized: Bool = false
    
    // MARK: - Initializers
    
    public required init() {
        self.isScanning = false
        self.queue = DispatchQueue.main
        initialize()
    }
    
    public required init(delegate: CBCentralManagerDelegateType?,
                         queue: DispatchQueue?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.delegate = delegate
        initialize()
    }
    
    public required init(delegate: CBCentralManagerDelegateType?,
                         queue: DispatchQueue?,
                         options: [String : Any]?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.delegate = delegate
        initialize()
    }
    
    private func initialize() {
        // Let's say this takes 10 ms. Less or more.
        queue.asyncAfter(deadline: .now() + .milliseconds(10)) { [weak self] in
            if let self = self {
                CBCentralManagerMock.managers.append(WeakRef(self))
                self.initialized = true
                self.delegate?.centralManagerDidUpdateState(self)
            }
        }
    }
    
    // MARK: - Central manager simulation methods
    
    /// Simulates turning the Bluetooth adapter on.
    /// The process will take the given amount of time.
    /// - Parameter duration: The transition interval. By default 100 ms.
    public static func simulatePowerOn(duration: TimeInterval = 0.1) {
        guard managerState != .poweredOn else {
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
            managerState = .poweredOn
        }
    }
    
    /// Simulate turns the Bluetooth adapter off.
    /// The process will take the given amount of time.
    /// - Parameter duration: The transition interval. By default 100 ms.
    public static func simulatePowerOff(duration: TimeInterval = 0.1) {
        guard managerState != .poweredOff else {
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
            managerState = .poweredOff
        }
    }
    
    /// Sets the initial state of the Bluetooth adapter. This method
    /// should only be called ones, before any `CBCentralManagerMock` is
    /// created. By defult, the initial state is `.poweredOff`.
    /// - Parameter state: The initial state of the Bluetooth adapter.
    public static func simulateInitialState(_ state: CBManagerStateType) {
        managerState = state
    }
    
    /// Sets the given peripherals for simulation. This method may only
    /// by called once, before any `CBCentralManagerMock` is created.
    /// - Parameter peripherals: Simulated peripherals.
    public static func simulatePeripherals(_ peripherals: [MockPeripheral]) {
        if mockPeripherals.isEmpty {
            mockPeripherals = peripherals
        }
    }
    
    // MARK: - CBCentralManager mock methods
    
    @available(iOS 13.0, *)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        return features.isSubset(of: .extendedScanAndConnect)
    }
    
    /// This is a Timer callback, that's called to emulate scanning for Bluetooth LE
    /// devices. When the `CBCentralManagerScanOptionAllowDuplicatesKey` options
    /// was set when scanning was started, the timer will repeat every advertising
    /// interval until scanning is stopped.
    ///
    /// The scanned peripheral is set as `userInfo`.
    /// - Parameter timer: The timer that is fired.
    @objc private func notify(timer: Timer) {
        guard let mock = timer.userInfo as? MockPeripheral,
              let advertisementData = mock.advertisementData,
              let peripheral = peripherals[mock.identifier],
              isScanning else {
            timer.invalidate()
            return
        }
        // Emulate RSSI based on proximity. Apply some deviation.
        let rssi = mock.proximity.RSSI
        let deviation = Int.random(in: -rssiDeviation...rssiDeviation)
        delegate?.centralManager(self, didDiscover: peripheral,
                                 advertisementData: advertisementData,
                                 rssi: (rssi + deviation) as NSNumber)
        // The first scan result is returned without a name.
        // This flag must then be called after it has been reported.
        // Setting this flag will cause the advertising name to be
        // returned from CBPeripheral.name.
        peripheral.wasScanned = true
    }
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?,
                                   options: [String : Any]?) {
        if isScanning {
            stopScan()
        }
        isScanning = true

        CBCentralManagerMock.mockPeripherals
            // For all advertising peripherals,
            .filter { $0.advertisementData   != nil
                   && $0.advertisingInterval != nil
                   && $0.advertisingInterval! > 0 }
            // that are either not conected, or advertise while connected,
            .filter { mock in
                mock.isAdvertisingWhenConnected ||
                (!mock.isInitiallyConnected &&
                    CBCentralManagerMock.managers.contains {
                        $0.ref?.peripherals[mock.identifier]?.state != .connected
                    }
                )
            }
            // do the following:
            .forEach { mock in
                // The central manager has scanned a device. Add it the list of known peripherals.
                if peripherals[mock.identifier] == nil {
                    peripherals[mock.identifier] = CBPeripheralMock(basedOn: mock,
                                                                    scannedBy: self)
                }
                // If no Service UUID was used, or the device matches at least one service,
                // report it to the delegate (call will be delayed using a Timer).
                let services = mock.advertisementData![CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
                if serviceUUIDs == nil ||
                   services?.contains(where: serviceUUIDs!.contains) ?? false {
                    // The timer will be called multiple times if option was set.
                    let allowDuplicates = options?[CBCentralManagerScanOptionAllowDuplicatesKey] as? NSNumber ?? false as NSNumber
                    let timer = Timer.scheduledTimer(timeInterval: mock.advertisingInterval!,
                                                     target: self,
                                                     selector: #selector(notify(timer:)),
                                                     userInfo: mock,
                                                     repeats: allowDuplicates.boolValue)
                    if allowDuplicates.boolValue {
                        scanTimers.append(timer)
                    }
                }
            }
    }
    
    public func stopScan() {
        isScanning = false
        scanTimers.forEach { $0.invalidate() }
        scanTimers.removeAll()
    }
    
    public func connect(_ peripheral: CBPeripheralType,
                        options: [String : Any]?) {
        // Central manager must be in powered on state.
        guard state == .poweredOn else {
            return
        }
        if let o = options, !o.isEmpty {
            NSLog("Warning: Connection options are not supported when mocking")
        }
        // Ignore peripherals that are not mocks, or are not in disconnected state.
        guard let mock = peripheral as? CBPeripheralMock,
              mock.state == .disconnected else {
            return
        }
        // The peripheral must come from this central manager. Ignore other.
        // To connect a peripheral obtained using another central manager
        // use `retrievePeripherals(withIdentifiers:)` or
        // `retrieveConnectedPeripherals(withServices:)`.
        guard peripherals.values.contains(mock) else {
            return
        }
        
        if let delegate = mock.connectionDelegate,
           let interval = mock.mock.connectionInterval {
            mock.state = .connecting
            switch delegate.peripheralDidReceiveConnectionRequest(mock.mock) {
            case .success:
                queue.asyncAfter(deadline: .now() + interval) {
                    mock.state = .connected
                    self.delegate?.centralManager(self, didConnect: mock)
                }
            case .failure(let error):
                queue.asyncAfter(deadline: .now() + interval) {
                    mock.state = .connected
                    self.delegate?.centralManager(self, didFailToConnect: mock,
                                                  error: error)
                }
            }
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        // Central manager must be in powered on state.
        guard state == .poweredOn else {
            return
        }
        // Ignore peripherals that are not mocks, or are not in disconnected state.
        guard let mock = peripheral as? CBPeripheralMock,
              mock.state == .connected || mock.state == .connecting else {
            return
        }
        // It is not possible to cancel connection of a peripheral obtained
        // from another central manager.
        guard peripherals.values.contains(mock) else {
            return
        }
        if #available(iOS 9.0, *) {
            mock.state = .disconnecting
        }
        queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            mock.state = .disconnected
            mock.services = nil
            self.delegate?.centralManager(self,
                                          didDisconnectPeripheral: mock,
                                          error: nil)
        }
    }
    
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralType] {
        // Starting from iOS 13, this method returns peripherals only in ON state.
        guard state == .poweredOn else {
            return []
        }
        // Get the peripherals already known to this central manager.
        let localPeripherals = peripherals[identifiers]
        // If all were found, return them.
        if localPeripherals.count == identifiers.count {
            return localPeripherals
        }
        let missingIdentifiers = identifiers.filter { peripherals[$0] == nil }
        // Otherwise, we need to look for them among other managers, and
        // copy them to the local manager.
        let peripheralsKnownByOtherManagers = missingIdentifiers
            .flatMap { i in
                CBCentralManagerMock.managers
                    .compactMap { $0.ref?.peripherals[i] }
            }
            .map { CBPeripheralMock(copy: $0, by: self) }
        peripheralsKnownByOtherManagers.forEach {
            peripherals[$0.identifier] = $0
        }
        // Return them in the same order as requested, some may be missing.
        return (localPeripherals + peripheralsKnownByOtherManagers)
            .sorted {
                let firstIndex = identifiers.firstIndex(of: $0.identifier)!
                let secondIndex = identifiers.firstIndex(of: $1.identifier)!
                return firstIndex < secondIndex
            }
    }
    
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralType] {
        guard state == .poweredOn else {
            // Starting from iOS 13, this method returns peripherals only in ON state.
            return []
        }
        // Get the connected peripherals with at least one of the given services
        // that are already known to this central manager.
        let localConnectedPeripherals = peripherals[serviceUUIDs]
            .filter { $0.state == .connected }
        // Other central managers also may know some connected peripherals that
        // are not known to the local one.
        let connectedPeripheralsKnownByOtherManagers = CBCentralManagerMock.managers
            // Get only those managers that were not disposed.
            .filter { $0.ref != nil }
            // Look for connected peripherals known to other managers.
            .flatMap {
                $0.ref!.peripherals[serviceUUIDs]
                    .filter { $0.state == .connected }
            }
            // Search for ones that are not known to the local manager.
            .filter { other in
                !localConnectedPeripherals.contains { local in
                    local.identifier == other.identifier
                }
            }
            // Create a local copy.
            .map { CBPeripheralMock(copy: $0, by: self) }
        // Add those copies to the local manager.
        connectedPeripheralsKnownByOtherManagers.forEach {
            peripherals[$0.identifier] = $0
        }
        return localConnectedPeripherals + connectedPeripheralsKnownByOtherManagers
    }
    
    @available(iOS 13.0, *)
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]?) {
        // Not implemented
    }
    
}

public class CBPeripheralMock: CBPeer, CBPeripheralType {
    public var delegate: CBPeripheralDelegateType?
    
    private let queue: DispatchQueue
    fileprivate let mock: MockPeripheral
    
    fileprivate var wasScanned: Bool   = false
    fileprivate var wasConnected: Bool = false
    fileprivate var connectionDelegate: MockPeripheralDelegate? {
        return mock.connectionDelegate
    }
    
    public override var identifier: UUID {
        return mock.identifier
    }
    public var name: String? {
        // If the device wasn't connected and has just been scanned first time,
        // return nil. When scanning continued, the Local Name from the
        // advertisment data is returned. When the device was connected, the
        // central reads the Device Name characteristic and returns cached value.
        return wasConnected ?
            mock.name :
            wasScanned ?
                mock.advertisementData?[CBAdvertisementDataLocalNameKey] as? String :
                nil
    }
    public fileprivate(set) var state: CBPeripheralState = .disconnected
    public fileprivate(set) var services: [CBServiceType]? = nil
    public fileprivate(set) var canSendWriteWithoutResponse: Bool = false
    public fileprivate(set) var ancsAuthorized: Bool = false
    
    fileprivate init(basedOn mock: MockPeripheral,
                     scannedBy central: CBCentralManagerMock) {
        self.mock = mock
        self.queue = central.queue
    }
    
    fileprivate init(copy: CBPeripheralMock, by central: CBCentralManagerMock) {
        self.mock = copy.mock
        self.queue = central.queue
    }
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              let allServices = mock.services else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveServiceDiscoveryRequest: serviceUUIDs) {
        case .success:
            services = services ?? []
            let initialSize = services!.count
            services = services! + allServices
                // Filter all device services that match given list (if set).
                .filter { serviceUUIDs?.contains($0.uuid) ?? true }
                // Filter those of them, that are not already in discovered services.
                .filter { s in !services!
                    .contains(where: { ds in s.identifier == ds.identifier })
                }
                // Copy the service info, without included services or characteristics.
                .map { CBServiceType(shallowCopy: $0, for: self) }
            let newServicesCount = services!.count - initialSize
            // Service discovery may takes the more time, the more services
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newServicesCount)) {
                self.delegate?.peripheral(self, didDiscoverServices: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self, didDiscoverServices: error)
            }
        }
    }
    
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?,
                                         for service: CBServiceType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              let allServices = mock.services else {
            return
        }
        guard let services = services, services.contains(service),
              let originalService = allServices.first(where: {
                  $0.identifier == service.identifier
              }) else {
            return
        }
        guard let originalIncludedServices = originalService.includedServices else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveIncludedServiceDiscoveryRequest: includedServiceUUIDs,
                                   for: service as! CBServiceMock) {
        case .success:
            service._includedServices = service._includedServices ?? []
            let initialSize = service._includedServices!.count
            service._includedServices = service._includedServices! +
                originalIncludedServices
                    // Filter all included service that match given list (if set).
                    .filter { includedServiceUUIDs?.contains($0.uuid) ?? true }
                    // Filter those of them, that are not already in discovered services.
                    .filter { s in !service._includedServices!
                        .contains(where: { ds in s.identifier == ds.identifier })
                    }
                    // Copy the service info, without included characterisitics.
                    .map { CBServiceType(shallowCopy: $0, for: self) }
            let newServicesCount = service._includedServices!.count - initialSize
            // Service discovery may takes the more time, the more services
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newServicesCount)) {
                self.delegate?.peripheral(self,
                                          didDiscoverIncludedServicesFor: service,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didDiscoverIncludedServicesFor: service,
                                          error: error)
            }
        }
        
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?,
                                        for service: CBServiceType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              let allServices = mock.services else {
            return
        }
        guard let services = services, services.contains(service),
              let originalService = allServices.first(where: {
                  $0.identifier == service.identifier
              }) else {
            return
        }
        guard let originalCharacteristics = originalService.characteristics else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveCharacteristicsDiscoveryRequest: characteristicUUIDs,
                                   for: service) {
        case .success:
            service._characteristics = service._characteristics ?? []
            let initialSize = service._characteristics!.count
            service._characteristics = service._characteristics! +
                originalCharacteristics
                    // Filter all service characteristics that match given list (if set).
                    .filter { characteristicUUIDs?.contains($0.uuid) ?? true }
                    // Filter those of them, that are not already in discovered characteritics.
                    .filter { c in !service._characteristics!
                        .contains(where: { dc in c.identifier == dc.identifier })
                    }
                    // Copy the characteristic info, without included descriptors or value.
                    .map { CBCharacteristicType(shallowCopy: $0, in: service) }
            let newCharacteristicsCount = service._characteristics!.count - initialSize
            // Characteristics discovery may takes the more time, the more characteristics
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newCharacteristicsCount)) {
                self.delegate?.peripheral(self,
                                          didDiscoverCharacteristicsFor: service,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didDiscoverCharacteristicsFor: service,
                                          error: error)
            }
        }
    }
    
    public func discoverDescriptors(for characteristic: CBCharacteristicType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              let allServices = mock.services else {
            return
        }
        guard let services = services, services.contains(characteristic.service),
              let originalService = allServices.first(where: {
                  $0.identifier == characteristic.service.identifier
              }),
              let originalCharacteristic = originalService.characteristics?.first(where: {
                  $0.identifier == characteristic.identifier
              }) else {
            return
        }
        guard let originalDescriptors = originalCharacteristic.descriptors else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveDescriptorsDiscoveryRequestFor: characteristic) {
        case .success:
            characteristic._descriptors = characteristic._descriptors ?? []
            let initialSize = characteristic._descriptors!.count
            characteristic._descriptors = characteristic._descriptors! +
                originalDescriptors
                    // Filter those of them, that are not already in discovered descriptors.
                    .filter { d in !characteristic._descriptors!
                        .contains(where: { dd in d.identifier == dd.identifier })
                    }
                    // Copy the descriptors info, without the value.
                    .map { CBDescriptorType(shallowCopy: $0, in: characteristic) }
            let newDescriptorsCount = characteristic._descriptors!.count - initialSize
            // Descriptors discovery may takes the more time, the more descriptors
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newDescriptorsCount)) {
                self.delegate?.peripheral(self,
                                          didDiscoverDescriptorsFor: characteristic,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didDiscoverDescriptorsFor: characteristic,
                                          error: error)
            }
        }
    }
    
    public func readValue(for characteristic: CBCharacteristicType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval else {
            return
        }
        guard let services = services,
              services.contains(characteristic.service) else {
            return
        }
        switch delegate.peripheral(mock,
                                   didReceiveReadRequestFor: characteristic) {
        case .success(let data):
            characteristic.value = data
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didUpdateValueFor: characteristic,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didUpdateValueFor: characteristic,
                                          error: error)
            }
        }
    }
    
    public func readValue(for descriptor: CBDescriptorType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval else {
            return
        }
        guard let services = services,
              services.contains(descriptor.characteristic.service) else {
            return
        }
        switch delegate.peripheral(mock,
                                   didReceiveReadRequestFor: descriptor) {
        case .success(let data):
            descriptor.value = data
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didUpdateValueFor: descriptor,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didUpdateValueFor: descriptor,
                                          error: error)
            }
        }
    }
    
    public func writeValue(_ data: Data,
                           for characteristic: CBCharacteristicType,
                           type: CBCharacteristicWriteType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval else {
            return
        }
        guard let services = services,
              services.contains(characteristic.service) else {
            return
        }
        
        if type == .withResponse {
            switch delegate.peripheral(mock,
                                       didReceiveWriteRequestFor: characteristic,
                                       data: data) {
            case .success:
                queue.asyncAfter(deadline: .now() + interval) {
                    self.delegate?.peripheral(self,
                                              didWriteValueFor: characteristic,
                                              error: nil)
                }
            case .failure(let error):
                queue.asyncAfter(deadline: .now() + interval) {
                    self.delegate?.peripheral(self,
                                              didWriteValueFor: characteristic,
                                              error: error)
                }
            }
        } else {
            delegate.peripheral(mock,
                                didReceiveWriteCommandFor: characteristic,
                                data: data)
        }
    }
    
    public func writeValue(_ data: Data, for descriptor: CBDescriptorType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval else {
            return
        }
        guard let services = services,
              services.contains(descriptor.characteristic.service) else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveWriteRequestFor: descriptor,
                                   data: data) {
        case .success:
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didWriteValueFor: descriptor,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didWriteValueFor: descriptor,
                                          error: error)
            }
        }
    }
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        guard state == .connected,
              let mtu = mock.mtu else {
            return 0
        }
        return type == .withResponse ? 512 : mtu - 3
    }
    
    public func setNotifyValue(_ enabled: Bool,
                               for characteristic: CBCharacteristicType) {
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval else {
            return
        }
        guard let services = services,
              services.contains(characteristic.service) else {
            return
        }
        guard enabled != characteristic.isNotifying else {
            return
        }
        
        switch delegate.peripheral(mock,
                                   didReceiveSetNotifyRequest: enabled,
                                   for: characteristic) {
        case .success:
            queue.asyncAfter(deadline: .now() + interval) {
                characteristic.isNotifying = enabled
                self.delegate?.peripheral(self,
                                          didUpdateNotificationStateFor: characteristic,
                                          error: nil)
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) {
                self.delegate?.peripheral(self,
                                          didUpdateNotificationStateFor: characteristic,
                                          error: error)
            }
        }        
    }
    
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        // TODO
    }
    
    public override var hash: Int {
        return mock.identifier.hashValue
    }
}

private class WeakRef<T: AnyObject> {
    fileprivate private(set) weak var ref: T?
    
    fileprivate init(_ value: T) {
        self.ref = value
    }
}

private extension Dictionary where Key == UUID, Value == CBPeripheralMock {
    
    subscript(identifiers: [UUID]) -> [CBPeripheralMock] {
        return identifiers.compactMap { self[$0] }
    }
    
    subscript(serviceUUIDs: [CBUUID]) -> [CBPeripheralMock] {
        return filter { (_, peripheral) in
            peripheral.services?
                .contains(where: { service in
                    serviceUUIDs.contains(service.uuid)
                })
            ?? false
        }.map { $0.value }
    }
    
}
