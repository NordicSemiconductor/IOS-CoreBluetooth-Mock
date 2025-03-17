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

import CoreBluetoothMock

// Copy this file to your project to start using CoreBluetoothMock classes
// without having to refactor any of your code. You will just have to remove
// the imports to CoreBluetooth to fix conflicts and initiate the manager
// using CBCentralManagerFactory, instead of just creating a CBCentralManager.

// disabled for Xcode 12.5 beta
//typealias CBPeer                          = CBMPeer
//typealias CBAttribute                     = CBMAttribute
typealias CBCentralManagerFactory         = CBMCentralManagerFactory
typealias CBUUID                          = CBMUUID
typealias CBError                         = CBMError
typealias CBATTError                      = CBMATTError
typealias CBManagerState                  = CBMManagerState
typealias CBPeripheralState               = CBMPeripheralState
typealias CBCentralManager                = CBMCentralManager
typealias CBCentralManagerDelegate        = CBMCentralManagerDelegate
typealias CBPeripheral                    = CBMPeripheral
typealias CBPeripheralDelegate            = CBMPeripheralDelegate
typealias CBService                       = CBMService
typealias CBCharacteristic                = CBMCharacteristic
typealias CBCharacteristicWriteType       = CBMCharacteristicWriteType
typealias CBCharacteristicProperties      = CBMCharacteristicProperties
typealias CBDescriptor                    = CBMDescriptor
typealias CBConnectionEvent               = CBMConnectionEvent
typealias CBConnectionEventMatchingOption = CBMConnectionEventMatchingOption
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
typealias CBL2CAPPSM                      = CBML2CAPPSM
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
typealias CBL2CAPChannel                  = CBML2CAPChannel

/// A Boolean value that specifies whether the scan should run without duplicate filtering.
///
/// The value for this key is an NSNumber object. If true, the central disables filtering and
/// generates a discovery event each time it receives an advertising packet from the peripheral.
/// If `false` (the default), the central coalesces multiple discoveries of the same peripheral
/// into a single discovery event.
///
/// - Important: Disabling this filtering can have an adverse effect on battery life;
///              use it only if necessary.
let CBCentralManagerScanOptionAllowDuplicatesKey       = CBMCentralManagerScanOptionAllowDuplicatesKey
/// An array of service UUIDs that you want to scan for.
///
/// The array is an instance of `NSArray`, and uses ``CBUUID`` objects to represent the UUIDs
/// to scan for.
///
/// Specifying this scan option causes the central manager to also scan for peripherals soliciting
/// any of the services contained in the array.
let CBCentralManagerScanOptionSolicitedServiceUUIDsKey = CBMCentralManagerScanOptionSolicitedServiceUUIDsKey
/// A Boolean value that specifies whether the system warns the user if the app instantiates
/// the central manager when Bluetooth service isn’t available.
///
/// The value for this key is an `NSNumber` object. If the key isn’t specified, the default value is `true`.
let CBCentralManagerOptionShowPowerAlertKey            = CBMCentralManagerOptionShowPowerAlertKey
/// A string containing a unique identifier (UID) for the central manager to instantiate.
///
/// The value for this key is an `NSString`. The system uses this UID to identify a specific
/// central manager. As a result, the UID must remain the same for subsequent executions
/// of the app to restore the central manager.
let CBCentralManagerOptionRestoreIdentifierKey         = CBMCentralManagerOptionRestoreIdentifierKey
/// An array of peripherals for use when restoring the state of a central manager.
///
/// The value associated with this key is an `NSArray` of `CBMPeripheralSpec` objects.
/// The array contains all of the peripherals connected to the central manager
/// (or had a pending connection) at the time the system terminated the app.
///
/// When possible, the system restores all information about a peripheral, including any
///  discovered services, characteristics, characteristic descriptors, and characteristic notification states.
let CBCentralManagerRestoredStatePeripheralsKey        = CBMCentralManagerRestoredStatePeripheralsKey
/// An array of service IDs for use when restoring state.
///
/// The value associated with this key is an `NSArray` of service UUIDs
/// (represented by ``CBUUID`` objects) containing all the services the central manager
/// was scanning for at the time the system terminated the app.
let CBCentralManagerRestoredStateScanServicesKey       = CBMCentralManagerRestoredStateScanServicesKey
/// A dictionary of peripheral scan options for use when restoring state.
///
/// The value associated with this key is an `NSDictionary`.
/// The dictionary contains all of the peripheral scan options in use by the central manager
/// when the system terminated the app.
let CBCentralManagerRestoredStateScanOptionsKey        = CBMCentralManagerRestoredStateScanOptionsKey

/// The local name of a peripheral.
///
/// The value associated with this key is an `NSString`.
let CBAdvertisementDataLocalNameKey                    = CBMAdvertisementDataLocalNameKey
/// A Boolean value that indicates whether the advertising event type is connectable.
///
/// The value for this key is an `NSNumber` object. You can use this value to determine
/// whether your app can currently connect to a peripheral.
let CBAdvertisementDataServiceUUIDsKey                 = CBMAdvertisementDataServiceUUIDsKey
/// A Boolean value that indicates whether the advertising event type is connectable.
///
/// The value for this key is an `NSNumber` object. You can use this value to determine
/// whether your app can currently connect to a peripheral.
let CBAdvertisementDataIsConnectable                   = CBMAdvertisementDataIsConnectable
/// The transmit power of a peripheral.
///
/// The value associated with this key is an instance of `NSNumber`.
///
/// This key and value are available if the peripheral provides its transmitting power level
/// in its advertising packet. You can calculate the path loss by comparing the RSSI
/// value with the transmitting power level.
let CBAdvertisementDataTxPowerLevelKey                 = CBMAdvertisementDataTxPowerLevelKey
/// A dictionary that contains service-specific advertisement data.
///
/// The keys (``CBUUID`` objects) represent ``CBService`` UUIDs, and the values
/// (`NSData` objects) represent service-specific data.
let CBAdvertisementDataServiceDataKey                  = CBMAdvertisementDataServiceDataKey
/// The manufacturer data of a peripheral.
///
/// The value associated with this key is an `NSData` object.
let CBAdvertisementDataManufacturerDataKey             = CBMAdvertisementDataManufacturerDataKey
/// An array of UUIDs found in the overflow area of the advertisement data.
///
/// The value associated with this key is an array of one or more ``CBUUID`` objects,
/// representing ``CBService`` UUIDs.
///
/// Because data stored in this area results from not fitting in the main advertisement,
/// UUIDs listed here are “best effort” and may not always be accurate. For details
/// about the overflow area of advertisement data, see the `startAdvertising(_:)`
/// method in `CBPeripheralManager`.
let CBAdvertisementDataOverflowServiceUUIDsKey         = CBMAdvertisementDataOverflowServiceUUIDsKey
/// An array of solicited service UUIDs.
///
/// The value associated with this key is an array of one or more ``CBUUID`` objects,
/// representing ``CBService`` UUIDs.
let CBAdvertisementDataSolicitedServiceUUIDsKey        = CBMAdvertisementDataSolicitedServiceUUIDsKey

/// An option that indicates a delay before the system makes a connection.
///
/// The corresponding value is an `NSNumber` that indicates the duration of the delay in seconds.
let CBConnectPeripheralOptionStartDelayKey             = CBMConnectPeripheralOptionStartDelayKey
#if !os(macOS)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
/// An option to require Apple Notification Center Service (ANCS) when connecting a device.
let CBConnectPeripheralOptionRequiresANCS              = CBMConnectPeripheralOptionRequiresANCS
#endif
/// A Boolean value that specifies whether the system should display an alert when
/// connecting a peripheral in the background.
///
/// The value for this key is an `NSNumber` object. This key is useful for apps that
/// haven’t specified the bluetooth-central background mode and can’t display their own alert.
/// If more than one app requests a notification for a given peripheral, the one that was
/// most recently in the foreground receives the alert. If the key isn’t specified, the default
/// value is `false`.
let CBConnectPeripheralOptionNotifyOnConnectionKey     = CBMConnectPeripheralOptionNotifyOnConnectionKey
/// A Boolean value that specifies whether the system should display an alert when
/// disconnecting a peripheral in the background.
///
/// The value for this key is an `NSNumber` object. This key is useful for apps that
/// haven’t specified the bluetooth-central background mode and can’t display their own alert.
/// If more than one app requests a notification for a given peripheral, the one that was
/// most recently in the foreground receives the alert. If the key isn’t specified, the default
/// value is `false`.
let CBConnectPeripheralOptionNotifyOnDisconnectionKey  = CBMConnectPeripheralOptionNotifyOnDisconnectionKey
/// A Boolean value that specifies whether the system should display an alert for any
/// notification sent by a peripheral.
///
/// If `true`, the system displays an alert for all notifications received from a given
/// peripheral while the app is suspended.
///
/// The value for this key is an `NSNumber` object. This key is useful for apps that
/// haven’t specified the bluetooth-central background mode and can’t display their own alert.
/// If more than one app requests a notification for a given peripheral, the one that was
/// most recently in the foreground receives the alert. If the key isn’t specified, the default
/// value is `false`.
let CBConnectPeripheralOptionNotifyOnNotificationKey   = CBMConnectPeripheralOptionNotifyOnNotificationKey
