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

/// A protocol that provides updates for the discovery and management of peripheral devices.
///
/// The `CBMCentralManagerDelegate` protocol defines the methods that a delegate of a
/// ``CBMCentralManager`` object must adopt. The optional methods of the protocol allow
/// the delegate to monitor the discovery, connectivity, and retrieval of peripheral devices.
///
/// The only required method is ``CBMCentralManagerDelegate/centralManagerDidUpdateState(_:)``;
/// the central manager calls this when its state updates, thereby indicating the availability of the central manager.
public protocol CBMCentralManagerDelegate: AnyObject {

    /// Invoked whenever the central manager's state has been updated.
    ///
    /// Commands should only be issued when the state is ``CBMManagerState/poweredOn``.
    ///
    /// Any other state implies that scanning has stopped and any
    /// connected peripherals have been disconnected.
    /// - Parameter central: The central manager whose state has changed.
    func centralManagerDidUpdateState(_ central: CBMCentralManager)
    
    /// For apps that opt-in to state preservation and restoration, this is the
    /// first method invoked when your app is relaunched into the background to
    /// complete some Bluetooth-related task.
    ///
    /// Use this method to synchronize your app's state with the state of the Bluetooth system.
    ///
    /// When mocking is enabled, the returned state is obtained using
    /// ``CBMCentralManagerMock/simulateStateRestoration``.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - dict: A dictionary containing information about central that was
    ///           preserved by the system at the time the app was terminated.
    func centralManager(_ central: CBMCentralManager,
                        willRestoreState dict: [String : Any])
    
    /// This method is invoked while scanning, upon the discovery of peripheral by
    /// central.
    ///
    /// A discovered peripheral must be retained in order to use it;
    /// otherwise, it is assumed to not be of interest and will be cleaned up by
    /// the central manager.
    ///
    /// For a list of advertisementData keys, see
    /// ``CBMAdvertisementDataLocalNameKey`` and other similar constants.
    /// - Parameters:
    ///   - central: The central manager providing this update.
    ///   - peripheral: A ``CBMPeripheral`` object.
    ///   - advertisementData: A dictionary containing any advertisement and scan
    ///                        response data.
    ///   - RSSI: The current RSSI of peripheral, in dBm. A value of 127 is
    ///           reserved and indicates the RSSI was not available.
    func centralManager(_ central: CBMCentralManager,
                        didDiscover peripheral: CBMPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)
    
    /// This method is invoked when a connection initiated by
    /// ``CBMCentralManager/connect(_:options:)`` has succeeded.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - peripheral: The ``CBMPeripheral`` that has connected.
    func centralManager(_ central: CBMCentralManager,
                        didConnect peripheral: CBMPeripheral)
    
    /// This method is invoked when a connection initiated by ``CBMCentralManager/connect(_:options:)``
    /// has failed to complete.
    ///
    /// As connection attempts do not timeout, the failure of a connection is atypical
    /// and usually indicative of a transient issue.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - peripheral: The ``CBMPeripheral`` that has failed to connect.
    ///   - error: The cause of the failure.
    func centralManager(_ central: CBMCentralManager,
                        didFailToConnect peripheral: CBMPeripheral,
                        error: Error?)
    
    /// This method is invoked upon the disconnection of a peripheral that was
    /// connected by ``CBMCentralManager/connect(_:options:)``.
    ///
    /// If the disconnection was not initiated by
    /// ``CBMCentralManager/cancelPeripheralConnection(_:)``,
    /// the cause will be detailed in the error parameter.
    ///
    /// Once this method has been called, no more methods will be
    /// invoked on peripheral's ``CBMPeripheralDelegate``.
    ///
    /// - Important: This callback will NOT be called when
    ///  ``centralManager(_:didDisconnectPeripheral:timestamp:isReconnecting:error:)``
    ///  has been implemented.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - peripheral: The ``CBMPeripheral`` that has disconnected.
    ///   - error: If an error occurred, the cause of the failure.∂
    func centralManager(_ central: CBMCentralManager,
                        didDisconnectPeripheral peripheral: CBMPeripheral,
                        error: Error?)
    
    /// This method is invoked upon the disconnection of a peripheral that was
    /// connected by ``CBMCentralManager/connect(_:options:)``.
    ///
    /// If peripheral is connected with option
    /// ``CBMConnectPeripheralOptionEnableAutoReconnect``,
    /// the system will automatically invoke connect to the peripheral and if connection
    /// is established with the peripheral afterwards,
    /// ``CBMCentralManagerDelegate/centralManager(_:didConnect:)-p052``
    /// can be invoked.
    ///
    /// If peripheral is connected without option
    /// ``CBMConnectPeripheralOptionEnableAutoReconnect``, once this
    /// method has been called, no more methods will be invoked peripheral's
    /// ``CBMPeripheralDelegate``.
    ///
    /// - Important: If this method is implemented,
    ///  ``centralManager(_:didDisconnectPeripheral:error:)``
    ///   will not be invoked. The CoreBluetooth Mock framework will call this method
    ///   on all iOS versions, despite the fact that the native API exists only since iOS 17+.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - peripheral: The ``CBMPeripheral`` that has disconnected.
    ///   - timestamp: Timestamp of the disconnection, it can be now or a few seconds ago.
    ///   - isReconnecting: If reconnect was triggered upon disconnection.
    ///   - error: If an error occurred, the cause of the failure.
    func centralManager(_ central: CBMCentralManager,
                        didDisconnectPeripheral peripheral: CBMPeripheral,
                        timestamp: CFAbsoluteTime,
                        isReconnecting: Bool,
                        error: (any Error)?)
    
    /// This method is invoked upon the connection or disconnection of a
    /// peripheral that matches any of the options provided in
    /// ``CBMCentralManager/registerForConnectionEvents(options:)``.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - event: The ``CBMConnectionEvent`` that has occurred.
    ///   - peripheral: The ``CBMPeripheral`` that caused the event.
    @available(iOS 13.0, *)
    func centralManager(_ central: CBMCentralManager,
                        connectionEventDidOccur event: CBMConnectionEvent,
                        for peripheral: CBMPeripheral)
    
    /// This method is invoked when the authorization status changes for a
    /// peripheral connected with ``CBMCentralManager/connect(_:options:)``
    /// option ``CBMConnectPeripheralOptionRequiresANCS``.
    ///
    /// - Important: This method is not implemented in mock central manager.
    /// - Parameters:
    ///   - central: The central manager providing this information.
    ///   - peripheral: The ``CBMPeripheral`` that caused the event.
    @available(iOS 13.0, *)
    func centralManager(_ central: CBMCentralManager,
                        didUpdateANCSAuthorizationFor peripheral: CBMPeripheral)
}

public extension CBMCentralManagerDelegate {
    
    func centralManager(_ central: CBMCentralManager,
                        willRestoreState dict: [String : Any]) {
        // optional method
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didDiscover peripheral: CBMPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        // optional method
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didConnect peripheral: CBMPeripheral) {
        // optional method
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didFailToConnect peripheral: CBMPeripheral,
                        error: Error?) {
        // optional method
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didDisconnectPeripheral peripheral: CBMPeripheral,
                        error: Error?) {
        // optional method
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didDisconnectPeripheral peripheral: CBMPeripheral,
                        timestamp: CFAbsoluteTime,
                        isReconnecting: Bool,
                        error: (any Error)?) {
        // If not implemented, call the standard
        // centralManager(_, didDisconnectPeripheral:, error:) method.
        centralManager(central,
                       didDisconnectPeripheral: peripheral,
                       error: error)
    }
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBMCentralManager,
                        connectionEventDidOccur event: CBMConnectionEvent,
                        for peripheral: CBMPeripheral) {
        // optional method
    }
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBMCentralManager,
                        didUpdateANCSAuthorizationFor peripheral: CBMPeripheral) {
        // optional method
    }
}
