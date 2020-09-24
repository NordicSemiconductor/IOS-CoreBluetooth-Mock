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

open class CBMCentralManagerMock: NSObject, CBMCentralManager {
    /// Mock RSSI deviation.
    ///
    /// Returned RSSI values will be in range
    /// `(base RSSI - deviation)...(base RSSI + deviation)`.
    fileprivate static let rssiDeviation = 15 // dBm
    
    /// A list of all mock managers instantiated by user.
    private static var managers: [WeakRef<CBMCentralManagerMock>] = []
    /// A list of peripherals known to the system.
    private static var peripherals: [CBMPeripheralSpec] = []
    /// The global state of the Bluetooth adapter on the device.
    fileprivate private(set) static var managerState: CBMManagerState = .poweredOff {
        didSet {
            // For all existing managers...
            managers
                .compactMap { $0.ref }
                .forEach { manager in
                    // ...stop scanning if state changed to any other state
                    // than `.poweredOn`. Also, forget all peripherals.
                    if managerState != .poweredOn {
                        manager.isScanning = false
                        manager.scanFilter = nil
                        manager.scanOptions = nil
                        manager.peripherals.values.forEach { $0.managerPoweredOff() }
                        manager.peripherals.removeAll()
                    }
                    // ...and notify delegate.
                    manager.queue.async {
                        manager.delegate?.centralManagerDidUpdateState(manager)
                    }
                }
            // Compact the list, if any of managers were disposed.
            managers.removeAll { $0.ref == nil }
        }
    }
    
    open weak var delegate: CBMCentralManagerDelegate?
    open var state: CBMManagerState {
        return initialized ? CBMCentralManagerMock.managerState : .unknown
    }
    open private(set) var isScanning: Bool
    private var scanFilter: [CBMUUID]?
    private var scanOptions: [String : Any]?

    /// The dispatch queue used for all callbacks.
    fileprivate let queue: DispatchQueue
    /// A map of peripherals known to this central manager.
    private var peripherals: [UUID : CBMPeripheralMock] = [:]
    /// A flag set to true few milliseconds after the manager is created.
    /// Some features, like the state or retrieving peripherals are not
    /// available when manager hasn't been initialized yet.
    private var initialized: Bool {
        // This method returns true if the manager is added to
        // the list of managers.
        // Calling tearDownSimulation() will remove all managers
        // from that list, making them uninitialized again.
        return CBMCentralManagerMock.managers.contains { $0.ref == self }
    }
    
    // MARK: - Initializers
    
    public required override init() {
        self.isScanning = false
        self.queue = DispatchQueue.main
        super.init()
        initialize()
    }
    
    public required init(delegate: CBMCentralManagerDelegate?,
                         queue: DispatchQueue?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.delegate = delegate
        super.init()
        initialize()
    }
    
    @available(iOS 7.0, *)
    public required init(delegate: CBMCentralManagerDelegate?,
                         queue: DispatchQueue?,
                         options: [String : Any]?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.delegate = delegate
        super.init()
        if let options = options,
           let identifierKey = options[CBMCentralManagerOptionRestoreIdentifierKey] as? String,
           let dict = CBMCentralManagerFactory
               .simulateStateRestoration?(identifierKey) {
            var state: [String : Any] = [:]
            if let peripheralKeys = dict[CBMCentralManagerRestoredStatePeripheralsKey] {
                state[CBMCentralManagerRestoredStatePeripheralsKey] = peripheralKeys
            }
            if let scanServiceKey = dict[CBMCentralManagerRestoredStateScanServicesKey] {
                state[CBMCentralManagerRestoredStateScanServicesKey] = scanServiceKey
            }
            if let scanOptions = dict[CBMCentralManagerRestoredStateScanOptionsKey] {
                state[CBMCentralManagerRestoredStateScanOptionsKey] = scanOptions
            }
            delegate?.centralManager(self, willRestoreState: state)
        }
        initialize()
    }
    
    private func initialize() {
        if CBMCentralManagerMock.managerState == .poweredOn &&
           CBMCentralManagerMock.peripherals.isEmpty {
            NSLog("Warning: No simulated peripherals. " +
                  "Call simulatePeripherals(:) before creating central manager")
        }
        // Let's say initialization takes 10 ms. Less or more.
        queue.asyncAfter(deadline: .now() + .milliseconds(10)) { [weak self] in
            if let self = self {
                CBMCentralManagerMock.managers.append(WeakRef(self))
                self.delegate?.centralManagerDidUpdateState(self)
            }
        }
    }
    
    /// Removes all active central manager instances and peripherals from the
    /// simulation, resetting it to the initial state.
    ///
    /// Use this to tear down your mocks between tests, e.g. in `tearDownWithError()`.
    /// All manager delegates will receive a `.unknown` state update.
    public static func tearDownSimulation() {
        // Set the state of all currently existing cenral manager instances to
        // .unknown, which will make them invalid.
        managerState = .unknown
        // Remove all central manager instances.
        managers.removeAll()
        // Set the manager state to powered Off.
        managerState = .poweredOff
        peripherals.removeAll()
    }
    
    // MARK: - Central manager simulation methods
    
    /// Sets the initial state of the Bluetooth central manager.
    ///
    /// This method should only be called ones, before any central manager
    /// is created. By default, the initial state is `.poweredOff`.
    /// - Parameter state: The initial state of the central manager.
    public static func simulateInitialState(_ state: CBMManagerState) {
        managerState = state
    }
    
    /// This method sets a list of simulated peripherals.
    ///
    /// Peripherals added using this method will be available for scanning
    /// and connecting, depending on their proximity. Use peripheral's
    /// `simulateProximity(of:didChangeTo:)` to modify proximity.
    ///
    /// This method may only be called before any central manager was created
    /// or when Bluetooth state is `.poweredOff`. Existing list of peripherals
    /// will be overritten.
    /// - Parameter peripherals: Peripherals specifications.
    public static func simulatePeripherals(_ peripherals: [CBMPeripheralSpec]) {
        guard managers.isEmpty || managerState == .poweredOff else {
            NSLog("Warning: Peripherals can not be added while the simulation is running. " +
                  "Add peripherals before getting any central manager instance, " +
                  "or when manager is powered off.")
            return
        }
        CBMCentralManagerMock.peripherals = peripherals
    }
    
    /// Simulates turning the Bluetooth adapter on.
    public static func simulatePowerOn() {
        guard managerState != .poweredOn else {
            return
        }
        managerState = .poweredOn
    }
    
    /// Simulate turning the Bluetooth adapter off.
    public static func simulatePowerOff() {
        guard managerState != .poweredOff else {
            return
        }
        managerState = .poweredOff
    }
    
    // MARK: - Peripheral simulation methods
    
    /// Simulates a situation when the given peripheral was moved closer
    /// or away from the phone.
    ///
    /// If the proximity is changed to `.outOfRange`, the peripheral will
    /// be disconnected and will not appear on scan results.
    /// - Parameter peripheral: The peripheral that was repositioned.
    /// - Parameter proximity: The new peripheral proximity.
    internal static func proximity(of peripheral: CBMPeripheralSpec,
                                   didChangeTo proximity: CBMProximity) {
        guard peripheral.proximity != proximity else {
            return
        }
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        peripheral.proximity = proximity
        
        if proximity == .outOfRange {
            self.peripheral(peripheral,
                            didDisconnectWithError: CBMError(.connectionTimeout))
        } else {
            self.peripheralBecameAvailable(peripheral)
        }
    }
    
    /// Simulates a situation when the device changes its services.
    /// - Parameters:
    ///   - peripheral: The peripheral that changed services.
    ///   - newName: New device name.
    ///   - newServices: New list of device services.
    internal static func peripheral(_ peripheral: CBMPeripheralSpec,
                                    didUpdateName newName: String?,
                                    andServices newServices: [CBMServiceMock]) {
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        peripheral.services = newServices

        guard peripheral.virtualConnections > 0 else {
            return
        }
        let existingManagers = managers.compactMap { $0.ref }
        existingManagers.forEach { manager in
            manager.peripherals[peripheral.identifier]?
                .notifyServicesChanged()
        }
        // Notify that the name has changed.
        if peripheral.name != newName {
            peripheral.name = newName
            existingManagers.forEach { manager in
                // TODO: This needs to be verified.
                //       Should a local peripheral copy be created if no such?
                //       Are all central managers notified about any device
                //       changing name?
                manager.peripherals[peripheral.identifier]?
                    .notifyNameChanged()
            }
        }
    }
    
    /// Simulates a notification sent from the peripheral.
    ///
    /// All central managers that have enabled notifications on it
    /// will receive `peripheral(:didUpdateValueFor:error)`.
    /// - Parameter characteristic: The characteristic from which
    ///                             notification is to be sent.
    internal static func peripheral(_ peripheral: CBMPeripheralSpec,
                                    didUpdateValueFor characteristic: CBMCharacteristicMock) {
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        guard peripheral.virtualConnections > 0 else {
            return
        }
        managers
            .compactMap { $0.ref }
            .forEach { manager in
                manager.peripherals[peripheral.identifier]?
                    .notifyValueChanged(for: characteristic)
            }
    }
    
    /// This method simulates a new virtual connection to the given
    /// peripheral, as if some other application connected to it.
    ///
    /// Central managers will not be notified about the state change unless
    /// they registered for connection events using
    /// `registerForConnectionEvents(options:)`.
    /// Even without registering (which is available since iOS 13), they
    /// can retrieve the connected peripheral using
    /// `retrieveConnectedPeripherals(withServices:)`.
    ///
    /// The peripheral does not need to be registered before.
    /// - Parameter peripheral: The peripheral that has connected.
    internal static func peripheralDidConnect(_ peripheral: CBMPeripheralSpec) {
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        peripheral.virtualConnections += 1
        
        // TODO: notify a user registered for connection events
    }
    
    /// Method called when a peripheral becomes available (in range).
    /// If there is a pending connection request, it will connect.
    /// - Parameter peripheral: The peripheral that came in range. 
    internal static func peripheralBecameAvailable(_ peripheral: CBMPeripheralSpec) {
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        managers
            .compactMap { $0.ref }
            .forEach { manager in
                if let target = manager.peripherals[peripheral.identifier],
                   target.state == .connecting {
                    target.connect() { result in
                        switch result {
                        case .success:
                            manager.delegate?.centralManager(manager, didConnect: target)
                        case .failure(let error):
                            manager.delegate?.centralManager(manager, didFailToConnect: target,
                                                             error: error)
                        }
                    }
                }
            }
    }
    
    /// Simulates the peripheral to disconnect from the device.
    /// All connected mock central managers will receive
    /// `peripheral(:didDisconnected:error)` callback.
    /// - Parameter peripheral: The peripheral to disconnect.
    /// - Parameter error: The disconnection reason. Use `CBError` or
    ///                    `CBATTError` errors.
    internal static func peripheral(_ peripheral: CBMPeripheralSpec,
                                    didDisconnectWithError error: Error =  CBError(.peripheralDisconnected)) {
        // Is the device connected at all?
        guard peripheral.isConnected else {
            return
        }
        // Is the peripheral simulated?
        guard peripherals.contains(peripheral) else {
            return
        }
        // The device has disconnected, so it can start advertising
        // immediately.
        peripheral.virtualConnections = 0
        // Notify all central managers.
        managers
            .compactMap { $0.ref }
            .forEach { manager in
                if let target = manager.peripherals[peripheral.identifier],
                    target.state == .connected {
                    target.disconnected(withError: error) { error in
                        manager.delegate?.centralManager(manager,
                                                         didDisconnectPeripheral: target,
                                                         error: error)
                    }
                }
            }
        // TODO: notify a user registered for connection events
    }
    
    // MARK: - CBCentralManager mock methods
    
    #if !os(macOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func supports(_ features: CBMCentralManager.Feature) -> Bool {
        return CBMCentralManagerFactory.simulateFeaturesSupport?(features) ?? false
    }
    #endif
    
    /// This is a Timer callback, that's called to emulate scanning for Bluetooth LE
    /// devices. When the `CBCentralManagerScanOptionAllowDuplicatesKey` options
    /// was set when scanning was started, the timer will repeat every advertising
    /// interval until scanning is stopped.
    ///
    /// The scanned peripheral is set as `userInfo`.
    /// - Parameter timer: The timer that is fired.
    @objc private func notify(timer: Timer) {
        guard let mock = timer.userInfo as? CBMPeripheralSpec,
              let advertisementData = mock.advertisementData,
              isScanning else {
            timer.invalidate()
            return
        }
        guard mock.proximity != .outOfRange else {
            return
        }
        guard !mock.isConnected || mock.isAdvertisingWhenConnected else {
            return
        }
        // Get or create local peripheral instance.
        if peripherals[mock.identifier] == nil {
            peripherals[mock.identifier] = CBMPeripheralMock(basedOn: mock,
                                                             by: self)
        }
        let peripheral = peripherals[mock.identifier]!
        
        // Emulate RSSI based on proximity. Apply some deviation.
        let rssi = mock.proximity.RSSI
        let delta = CBMCentralManagerMock.rssiDeviation
        let deviation = Int.random(in: -delta...delta)
        delegate?.centralManager(self, didDiscover: peripheral,
                                 advertisementData: advertisementData,
                                 rssi: (rssi + deviation) as NSNumber)
        // The first scan result is returned without a name.
        // This flag must then be called after it has been reported.
        // Setting this flag will cause the advertising name to be
        // returned from CBPeripheral.name.
        peripheral.wasScanned = true
        
        let allowDuplicates = scanOptions?[CBMCentralManagerScanOptionAllowDuplicatesKey] as? NSNumber ?? false as NSNumber
        if !allowDuplicates.boolValue {
            timer.invalidate()
        }
    }
    
    open func scanForPeripherals(withServices serviceUUIDs: [CBMUUID]?,
                                   options: [String : Any]?) {
        // Central manager must be in powered on state.
        guard ensurePoweredOn() else { return }
        if isScanning {
            stopScan()
        }
        isScanning = true
        scanFilter = serviceUUIDs
        scanOptions = options

        CBMCentralManagerMock.peripherals
            // For all advertising peripherals,
            .filter { $0.advertisementData   != nil
                   && $0.advertisingInterval != nil
                   && $0.advertisingInterval! > 0 }
            .forEach { mock in
                // If no Service UUID was used, or the device matches at least one service,
                // report it to the delegate (call will be delayed using a Timer).
                let services = mock.advertisementData![CBMAdvertisementDataServiceUUIDsKey] as? [CBMUUID]
                if serviceUUIDs == nil ||
                   services?.contains(where: serviceUUIDs!.contains) ?? false {
                    // The timer will be called multiple times, even if
                    // CBCentralManagerScanOptionAllowDuplicatesKey was not set.
                    // In that case, the timer will be invalidated after the
                    // device has been reported for the first time.
                    //
                    // Timer works only on queues with a active run loop.
                    DispatchQueue.main.async {
                        Timer.scheduledTimer(
                            timeInterval: mock.advertisingInterval!,
                            target: self,
                            selector: #selector(self.notify(timer:)),
                            userInfo: mock,
                            repeats: true
                        )
                    }
                }
            }
    }
    
    open func stopScan() {
        // Central manager must be in powered on state.
        guard ensurePoweredOn() else { return }
        isScanning = false
        scanFilter = nil
        scanOptions = nil
    }
    
    open func connect(_ peripheral: CBMPeripheral,
                        options: [String : Any]?) {
        // Central manager must be in powered on state.
        guard ensurePoweredOn() else { return }
        if let o = options, !o.isEmpty {
            NSLog("Warning: Connection options are not supported in mock central manager")
        }
        // Ignore peripherals that are not mocks.
        guard let mock = peripheral as? CBMPeripheralMock else {
            return
        }
        // The peripheral must come from this central manager. Ignore other.
        // To connect a peripheral obtained using another central manager
        // use `retrievePeripherals(withIdentifiers:)` or
        // `retrieveConnectedPeripherals(withServices:)`.
        guard peripherals.values.contains(mock) else {
            return
        }
        mock.connect() { result in
            switch result {
            case .success:
                self.delegate?.centralManager(self, didConnect: mock)
            case .failure(let error):
                self.delegate?.centralManager(self, didFailToConnect: mock,
                                              error: error)
            }
        }
    }
    
    open func cancelPeripheralConnection(_ peripheral: CBMPeripheral) {
        // Central manager must be in powered on state.
        guard ensurePoweredOn() else { return }
        // Ignore peripherals that are not mocks.
        guard let mock = peripheral as? CBMPeripheralMock else {
            return
        }
        // It is not possible to cancel connection of a peripheral obtained
        // from another central manager.
        guard peripherals.values.contains(mock) else {
            return
        }
        mock.disconnect() {
            self.delegate?.centralManager(self, didDisconnectPeripheral: mock,
                                          error: nil)
        }
    }
    
    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBMPeripheral] {
        // Starting from iOS 13, this method returns peripherals only in ON state.
        guard ensurePoweredOn() else { return [] }
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
                CBMCentralManagerMock.managers
                    .compactMap { $0.ref?.peripherals[i] }
            }
            .map { CBMPeripheralMock(copy: $0, by: self) }
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
    
    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBMUUID]) -> [CBMPeripheral] {
        // Starting from iOS 13, this method returns peripherals only in ON state.
        guard ensurePoweredOn() else { return [] }
        // Get the connected peripherals with at least one of the given services
        // that are already known to this central manager.
        let peripheralsConnectedByThisManager = peripherals[serviceUUIDs]
            .filter { $0.state == .connected }
        // Other central managers may know some connected peripherals that
        // are not known to the local one.
        let peripheralsConnectedByOtherManagers = CBMCentralManagerMock.managers
            // Get only those managers that were not disposed.
            .filter { $0.ref != nil }
            // Look for connected peripherals known to other managers.
            .flatMap {
                $0.ref!.peripherals[serviceUUIDs]
                    .filter { $0.state == .connected }
            }
            // Search for ones that are not known to the local manager.
            .filter { peripherals[$0.identifier] == nil }
            // Create a local copy.
            .map { CBMPeripheralMock(copy: $0, by: self) }
        // Add those copies to the local manager.
        peripheralsConnectedByOtherManagers.forEach {
            peripherals[$0.identifier] = $0
        }
        let peripheralsConnectedByOtherApps = CBMCentralManagerMock.peripherals
            .filter { $0.isConnected }
            // Search for ones that are not known to the local manager.
            .filter { peripherals[$0.identifier] == nil }
            // And only those that match any of given service UUIDs.
            .filter {
                $0.services!.contains { service in
                    serviceUUIDs.contains(service.uuid)
                }
            }
            // Create a local copy.
            .map { CBMPeripheralMock(basedOn: $0, by: self) }
        return peripheralsConnectedByThisManager
             + peripheralsConnectedByOtherManagers
             + peripheralsConnectedByOtherApps
    }
    
    @available(iOS 13.0, *)
    open func registerForConnectionEvents(options: [CBMConnectionEventMatchingOption : Any]?) {
        fatalError("Mock connection events are not implemented")
    }
    
    fileprivate func ensurePoweredOn() -> Bool {
        guard state == .poweredOn else {
            NSLog("[CoreBluetoothMock] API MISUSE: \(self) can only accept this command while in the powered on state")
            return false
        }
        return true
    }
    
}

// MARK: - CBPeripheralMock implementation

open class CBMPeripheralMock: CBMPeer, CBMPeripheral {
    
    /// The parent central manager.
    private let manager: CBMCentralManagerMock
    /// The dispatch queue to call delegate methods on.
    private var queue: DispatchQueue {
        return manager.queue
    }
    /// The mock peripheral with user-defined implementation.
    private let mock: CBMPeripheralSpec
    /// Size of the outgoing buffer. Only this many packets
    /// can be written without response in a loop, without
    /// waiting for `canSendWriteWithoutResponse`.
    private let bufferSize =  20
    /// The supervision timeout is a time after which a device realizes
    /// that a connected peer has disconnected, had there been no signal
    /// from it.
    private let supervisionTimeout = 4.0
    /// The current buffer size.
    private var availableWriteWithoutResponseBuffer: Int
    private var _canSendWriteWithoutResponse: Bool = false
    
    /// A flag set to <i>true</i> when the device was scanned
    /// at least once.
    fileprivate var wasScanned: Bool   = false
    /// A flag set to <i>true</i> when the device was connected
    /// and iOS had chance to read device name.
    fileprivate var wasConnected: Bool = false
    
    open var delegate: CBMPeripheralDelegate?
    
    open override var identifier: UUID {
        return mock.identifier
    }
    open var name: String? {
        // If the device wasn't connected and has just been scanned first time,
        // return nil. When scanning continued, the Local Name from the
        // advertisement data is returned. When the device was connected, the
        // central reads the Device Name characteristic and returns cached value.
        return wasConnected ?
            mock.name :
            wasScanned ?
                mock.advertisementData?[CBMAdvertisementDataLocalNameKey] as? String :
                nil
    }
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    open var canSendWriteWithoutResponse: Bool {
        return _canSendWriteWithoutResponse
    }
    open private(set) var ancsAuthorized: Bool = false
    open private(set) var state: CBMPeripheralState = .disconnected
    open private(set) var services: [CBMService]? = nil
    
    // MARK: Initializers
    
    fileprivate init(basedOn mock: CBMPeripheralSpec,
                     by manager: CBMCentralManagerMock) {
        self.mock = mock
        self.manager = manager
        self.availableWriteWithoutResponseBuffer = bufferSize
    }
    
    fileprivate init(copy: CBMPeripheralMock,
                     by manager: CBMCentralManagerMock) {
        self.mock = copy.mock
        self.manager = manager
        self.availableWriteWithoutResponseBuffer = bufferSize
    }
    
    // MARK: Connection
    
    fileprivate func connect(completion: @escaping (Result<Void, Error>) -> ()) {
        // Ensure the device is disconnected.
        guard state == .disconnected || state == .connecting else {
            return
        }
        // Connection is pending.
        state = .connecting
        // Ensure the device is connectable and in range.
        guard let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              mock.proximity != .outOfRange else {
            // There's no timeout on iOS. The device will connect when brought back
            // into range. To cancel pending connection, call disconnect().
            return
        }
        let result = delegate.peripheralDidReceiveConnectionRequest(mock)
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, self.state == .connecting {
                if case .success = result {
                    self.state = .connected
                    self._canSendWriteWithoutResponse = true
                    self.mock.virtualConnections += 1
                } else {
                    self.state = .disconnected
                }
                completion(result)
            }
        }
    }
    
    fileprivate func disconnect(completion: @escaping () -> ()) {
        // Cancel pending connection.
        guard state != .connecting else {
            state = .disconnected
            queue.async {
                completion()
            }
            return
        }
        // Ensure the device is connectable and connected.
        guard let interval = mock.connectionInterval,
              state == .connected else {
            return
        }
        if #available(iOS 9.0, *), case .connected = state {
            state = .disconnecting
        }
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, CBMCentralManagerMock.managerState == .poweredOn {
                self.state = .disconnected
                self.services = nil
                self._canSendWriteWithoutResponse = false
                self.mock.virtualConnections -= 1
                self.mock.connectionDelegate?.peripheral(self.mock,
                                                         didDisconnect: nil)
                completion()
            }
        }
    }
    
    fileprivate func disconnected(withError error: Error,
                                  completion: @escaping (Error?) -> ()) {
        // Ensure the device is connected.
        guard var interval = mock.connectionInterval,
              state == .connected else {
            return
        }
        // If a device disconnected with a timeout, the central waits
        // for the duration of supervision timeout before accepting
        // disconnection.
        if let error = error as? CBMError, error.code == .connectionTimeout {
            interval = supervisionTimeout
        }
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, CBMCentralManagerMock.managerState == .poweredOn {
                self.state = .disconnected
                self.services = nil
                self._canSendWriteWithoutResponse = false
                // If the disconnection happen without an error, the device
                // must have been disconnected disconnected from central
                // manager.
                self.mock.virtualConnections = 0
                self.mock.connectionDelegate?.peripheral(self.mock,
                                                         didDisconnect: error)
                completion(error)
            }
        }
    }
    
    // MARK: Service modification
    
    fileprivate func notifyNameChanged() {
        guard state == .connected,
              let interval = mock.connectionInterval else {
            return
        }
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, self.state == .connected {
                self.delegate?.peripheralDidUpdateName(self)
            }
        }
    }
    
    fileprivate func notifyServicesChanged() {
        guard state == .connected,
              let oldServices = services,
              let interval = mock.connectionInterval else {
            return
        }
        
        // Keep only services that hadn't changed.
        services = services!
            .filter { service in
                mock.services!.contains(where: {
                    $0.identifier == service.identifier
                })
            }
        let invalidatedServices = oldServices.filter({ !services!.contains($0) })
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, self.state == .connected {
                self.delegate?.peripheral(self, didModifyServices: invalidatedServices)
            }
        }
    }
    
    fileprivate func notifyValueChanged(for originalCharacteristic: CBMCharacteristicMock) {
        guard state == .connected,
              let interval = mock.connectionInterval,
              let service = services?.first(where: {
                $0.characteristics?.contains(where: {
                    $0.identifier == originalCharacteristic.identifier
                }) ?? false
              }),
              let characteristic = service.characteristics?.first(where: {
                  $0.identifier == originalCharacteristic.identifier
              }),
              characteristic.isNotifying else {
            return
        }
        characteristic.value = originalCharacteristic.value
        queue.asyncAfter(deadline: .now() + interval) { [weak self] in
            if let self = self, self.state == .connected {
                self.delegate?.peripheral(self,
                                          didUpdateValueFor: characteristic,
                                          error: nil)
            }
        }
    }
    
    fileprivate func managerPoweredOff() {
        state = .disconnected
        services = nil
        _canSendWriteWithoutResponse = false
        mock.virtualConnections = 0
    }
    
    // MARK: Service discovery
    
    open func discoverServices(_ serviceUUIDs: [CBMUUID]?) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
                .map { CBMService(shallowCopy: $0, for: self) }
            let newServicesCount = services!.count - initialSize
            // Service discovery may takes the more time, the more services
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newServicesCount)) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self, didDiscoverServices: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self, didDiscoverServices: error)
                }
            }
        }
    }
    
    open func discoverIncludedServices(_ includedServiceUUIDs: [CBMUUID]?,
                                         for service: CBMService) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
                                   for: service as! CBMServiceMock) {
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
                    // Copy the service info, without included characteristics.
                    .map { CBMService(shallowCopy: $0, for: self) }
            let newServicesCount = service._includedServices!.count - initialSize
            // Service discovery may takes the more time, the more services
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newServicesCount)) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverIncludedServicesFor: service,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverIncludedServicesFor: service,
                                              error: error)
                }
            }
        }
        
    }
    
    open func discoverCharacteristics(_ characteristicUUIDs: [CBMUUID]?,
                                        for service: CBMService) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
                    // Filter those of them, that are not already in discovered characteristics.
                    .filter { c in !service._characteristics!
                        .contains(where: { dc in c.identifier == dc.identifier })
                    }
                    // Copy the characteristic info, without included descriptors or value.
                    .map { CBMCharacteristic(shallowCopy: $0, in: service) }
            let newCharacteristicsCount = service._characteristics!.count - initialSize
            // Characteristics discovery may takes the more time, the more characteristics
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newCharacteristicsCount)) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverCharacteristicsFor: service,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverCharacteristicsFor: service,
                                              error: error)
                }
            }
        }
    }
    
    open func discoverDescriptors(for characteristic: CBMCharacteristic) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
                    .map { CBMDescriptor(shallowCopy: $0, in: characteristic) }
            let newDescriptorsCount = characteristic._descriptors!.count - initialSize
            // Descriptors discovery may takes the more time, the more descriptors
            // are discovered.
            queue.asyncAfter(deadline: .now() + interval * Double(newDescriptorsCount)) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverDescriptorsFor: characteristic,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didDiscoverDescriptorsFor: characteristic,
                                              error: error)
                }
            }
        }
    }
    
    // MARK: Read requests
    
    open func readValue(for characteristic: CBMCharacteristic) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didUpdateValueFor: characteristic,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didUpdateValueFor: characteristic,
                                              error: error)
                }
            }
        }
    }
    
    open func readValue(for descriptor: CBMDescriptor) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didUpdateValueFor: descriptor,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didUpdateValueFor: descriptor,
                                              error: error)
                }
            }
        }
    }
    
    // MARK: Write requests
    
    open func writeValue(_ data: Data,
                           for characteristic: CBMCharacteristic,
                           type: CBMCharacteristicWriteType) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
        guard state == .connected,
              let delegate = mock.connectionDelegate,
              let interval = mock.connectionInterval,
              let mtu = mock.mtu else {
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
                let packetsCount = max(1, (data.count + mtu - 2) / (mtu - 3))
                queue.asyncAfter(deadline: .now() + interval * Double(packetsCount)) { [weak self] in
                    if let self = self, self.state == .connected {
                        self.delegate?.peripheral(self,
                                                  didWriteValueFor: characteristic,
                                                  error: nil)
                    }
                }
            case .failure(let error):
                queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                    if let self = self, self.state == .connected {
                        self.delegate?.peripheral(self,
                                                  didWriteValueFor: characteristic,
                                                  error: error)
                    }
                }
            }
        } else {
            let decreaseBuffer = { [weak self] in
                guard let strongSelf = self,
                    strongSelf.availableWriteWithoutResponseBuffer > 0 else {
                    return
                }
                strongSelf.availableWriteWithoutResponseBuffer -= 1
                strongSelf._canSendWriteWithoutResponse = false
            }
            if DispatchQueue.main.label == queue.label {
                decreaseBuffer()
            } else {
                queue.sync {
                    decreaseBuffer()
                }
            }
            
            delegate.peripheral(mock,
                                didReceiveWriteCommandFor: characteristic,
                                data: data.subdata(in: 0..<mtu - 3))
            queue.async { [weak self] in
                if let self = self, self.state == .connected {
                    let increaseBuffer = {
                        self.availableWriteWithoutResponseBuffer += 1
                        self._canSendWriteWithoutResponse = true
                    }
                    if DispatchQueue.main.label == self.queue.label {
                        increaseBuffer()
                    } else {
                        self.queue.sync {
                            increaseBuffer()
                        }
                    }
                    if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
                        self.delegate?.peripheralIsReady(toSendWriteWithoutResponse: self)
                    }
                }
            }
        }
    }
    
    open func writeValue(_ data: Data, for descriptor: CBMDescriptor) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didWriteValueFor: descriptor,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didWriteValueFor: descriptor,
                                              error: error)
                }
            }
        }
    }
    
    @available(iOS 9.0, *)
    open func maximumWriteValueLength(for type: CBMCharacteristicWriteType) -> Int {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return 0 }
        guard state == .connected, let mtu = mock.mtu else {
            return 0
        }
        return type == .withResponse ? 512 : mtu - 3
    }
    
    // MARK: Enabling notifications and indications
    
    open func setNotifyValue(_ enabled: Bool,
                               for characteristic: CBMCharacteristic) {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
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
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    characteristic.isNotifying = enabled
                    self.delegate?.peripheral(self,
                                              didUpdateNotificationStateFor: characteristic,
                                              error: nil)
                }
            }
        case .failure(let error):
            queue.asyncAfter(deadline: .now() + interval) { [weak self] in
                if let self = self, self.state == .connected {
                    self.delegate?.peripheral(self,
                                              didUpdateNotificationStateFor: characteristic,
                                              error: error)
                }
            }
        }        
    }
    
    // MARK: Other
    
    open func readRSSI() {
        // Central manager must be in powered on state.
        guard manager.ensurePoweredOn() else { return }
        queue.async { [weak self] in
            if let self = self, self.state == .connected {
                let rssi = self.mock.proximity.RSSI
                let delta = CBMCentralManagerMock.rssiDeviation
                let deviation = Int.random(in: -delta...delta)
                self.delegate?.peripheral(self, didReadRSSI: (rssi + deviation) as NSNumber,
                                          error: nil)
            }
        }
    }
    
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    open func openL2CAPChannel(_ PSM: CBML2CAPPSM) {
        fatalError("L2CAP mock is not implemented")
    }
    
    open override var hash: Int {
        return mock.identifier.hashValue
    }
}

// MARK: - Helpers

private class WeakRef<T: AnyObject> {
    fileprivate private(set) weak var ref: T?
    
    fileprivate init(_ value: T) {
        self.ref = value
    }
}

private extension Dictionary where Key == UUID, Value == CBMPeripheralMock {
    
    subscript(identifiers: [UUID]) -> [CBMPeripheralMock] {
        return identifiers.compactMap { self[$0] }
    }
    
    subscript(serviceUUIDs: [CBMUUID]) -> [CBMPeripheralMock] {
        return filter { (_, peripheral) in
            peripheral.services?
                .contains(where: { service in
                    serviceUUIDs.contains(service.uuid)
                })
            ?? false
        }.map { $0.value }
    }
    
}
