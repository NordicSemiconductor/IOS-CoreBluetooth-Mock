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

public enum CBMManagerState: Int {

    case unknown

    case resetting

    case unsupported

    case unauthorized

    case poweredOff

    case poweredOn
}

// disabled for Xcode 12.5 beta
//public typealias CBMPeer = CBPeer
//public typealias CBMAttribute = CBAttribute
public typealias CBMUUID = CBUUID
public typealias CBMError = CBError
public typealias CBMATTError = CBATTError
public typealias CBMConnectionEvent = CBConnectionEvent
public typealias CBMConnectionEventMatchingOption = CBConnectionEventMatchingOption
public typealias CBMPeripheralState = CBPeripheralState
public typealias CBMCharacteristicWriteType = CBCharacteristicWriteType
public typealias CBMCharacteristicProperties = CBCharacteristicProperties
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public typealias CBML2CAPPSM = CBL2CAPPSM
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public typealias CBML2CAPChannel = CBL2CAPChannel

public let CBMCentralManagerScanOptionAllowDuplicatesKey = CBCentralManagerScanOptionAllowDuplicatesKey
public let CBMCentralManagerOptionShowPowerAlertKey = CBCentralManagerOptionShowPowerAlertKey
public let CBMCentralManagerOptionRestoreIdentifierKey = CBCentralManagerOptionRestoreIdentifierKey
public let CBMCentralManagerScanOptionSolicitedServiceUUIDsKey = CBCentralManagerScanOptionSolicitedServiceUUIDsKey
public let CBMConnectPeripheralOptionStartDelayKey = CBConnectPeripheralOptionStartDelayKey
#if !os(macOS)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public let CBMConnectPeripheralOptionRequiresANCS = CBConnectPeripheralOptionRequiresANCS
#endif
public let CBMCentralManagerRestoredStatePeripheralsKey  = CBCentralManagerRestoredStatePeripheralsKey
public let CBMCentralManagerRestoredStateScanServicesKey = CBCentralManagerRestoredStateScanServicesKey
public let CBMCentralManagerRestoredStateScanOptionsKey  = CBCentralManagerRestoredStateScanOptionsKey

public let CBMAdvertisementDataLocalNameKey             = CBAdvertisementDataLocalNameKey
public let CBMAdvertisementDataServiceUUIDsKey          = CBAdvertisementDataServiceUUIDsKey
public let CBMAdvertisementDataIsConnectable            = CBAdvertisementDataIsConnectable
public let CBMAdvertisementDataTxPowerLevelKey          = CBAdvertisementDataTxPowerLevelKey
public let CBMAdvertisementDataServiceDataKey           = CBAdvertisementDataServiceDataKey
public let CBMAdvertisementDataManufacturerDataKey      = CBAdvertisementDataManufacturerDataKey
public let CBMAdvertisementDataOverflowServiceUUIDsKey  = CBAdvertisementDataOverflowServiceUUIDsKey
public let CBMAdvertisementDataSolicitedServiceUUIDsKey = CBAdvertisementDataSolicitedServiceUUIDsKey

public let CBMConnectPeripheralOptionNotifyOnConnectionKey = CBConnectPeripheralOptionNotifyOnConnectionKey
public let CBMConnectPeripheralOptionNotifyOnDisconnectionKey = CBConnectPeripheralOptionNotifyOnDisconnectionKey
public let CBMConnectPeripheralOptionNotifyOnNotificationKey = CBConnectPeripheralOptionNotifyOnNotificationKey
