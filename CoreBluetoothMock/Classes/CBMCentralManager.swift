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

public protocol CBMCentralManager: AnyObject {
    #if !os(macOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    typealias Feature = CBCentralManager.Feature
    #endif
    
    /// The delegate object that will receive central events.
    var delegate: CBMCentralManagerDelegate? { get set }
    
    /// The current state of the manager, initially set to
    /// `CBManagerStateUnknown`. Updates are provided by required delegate
    /// method `centralManagerDidUpdateState(_:)`.
    var state: CBMManagerState { get }
    
    /// Whether or not the central is currently scanning.
    @available(iOS 9.0, *)
    var isScanning: Bool { get }
    
    /// Returns a boolean value representing the support for the provided features.
    /// - Parameter features: One or more features you would like to check if supported.
    #if !os(macOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func supports(_ features: CBMCentralManager.Feature) -> Bool
    #endif
    
    /// Starts scanning for peripherals that are advertising any of the services listed
    /// in serviceUUIDs. Although strongly discouraged, if serviceUUIDs
    /// is nil all discovered peripherals will be returned. If the central is
    /// already scanning with different serviceUUIDs or options, the
    /// provided parameters will replace them. Applications that have specified the
    /// `bluetooth-central` background mode are allowed to scan while
    /// backgrounded, with two caveats: the scan must specify one or more service types
    /// in serviceUUIDs, and the `CBCentralManagerScanOptionAllowDuplicatesKey`
    /// scan option will be ignored.
    /// - Parameters:
    ///   - serviceUUIDs: A list of `CBUUID` objects representing the service(s)
    ///                   to scan for.
    ///   - options: An optional dictionary specifying options for the scan.
    func scanForPeripherals(withServices serviceUUIDs: [CBMUUID]?, options: [String : Any]?)
    
    /// Stops scanning for peripherals.
    func stopScan()
    
    /// Initiates a connection to peripheral. Connection attempts never time out
    /// and, depending on the outcome, will result in a call to either
    /// `centralManager(didConnect:)` or `centralManager(didFailToConnect:error:)`.
    /// Pending attempts are cancelled automatically upon deallocation of peripheral,
    /// and explicitly via `cancelPeripheralConnection(_:)`.
    /// - Parameters:
    ///   - peripheral: The `CBMPeripheral` to be connected.
    ///   - options: An optional dictionary specifying connection behavior options.
    func connect(_ peripheral: CBMPeripheral, options: [String : Any]?)
    
    /// Cancels an active or pending connection to peripheral. Note that this
    /// is non-blocking, and any `CBMPeripheral` commands that are still
    /// pending to peripheral may or may not complete.
    /// - Parameter peripheral: A `CBMPeripheral`.
    func cancelPeripheralConnection(_ peripheral: CBMPeripheral)
    
    /// Attempts to retrieve the `CBMPeripheral` object(s) with the
    /// corresponding identifiers.
    /// - Parameter identifiers: A list of `UUID` objects.
    @available(iOS 7.0, *)
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBMPeripheral]
    
    /// Retrieves all peripherals that are connected to the system and implement
    /// any of the services listed in serviceUUIDs.
    /// Note that this set can include peripherals which were connected by other
    /// applications, which will need to be connected locally via
    /// `connect(peripheral:options:)` before they can be used.
    /// - Returns: A list of `CBMPeripheral` objects.
    @available(iOS 7.0, *)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBMUUID]) -> [CBMPeripheral]
    
    /// Calls `centralManager(:connectionEventDidOccur:for:)` when a connection event
    /// occurs matching any of the given options. Passing nil in the option parameter
    /// clears any prior registered matching options.
    /// - Parameter options: A dictionary specifying connection event options.
    #if !os(macOS)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func registerForConnectionEvents(options: [CBMConnectionEventMatchingOption : Any]?)
    #endif
}
