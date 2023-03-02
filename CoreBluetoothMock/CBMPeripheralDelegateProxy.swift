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

/// A helper class that allows setting delegate callbacks as closures.
///
/// - SeeAlso: ``CBMPeripheralDelegate``
open class CBMPeripheralDelegateProxy: NSObject, CBMPeripheralDelegate {
    public var didUpdateName: ((CBMPeripheral) -> ())?
    public var didModifyServices: ((CBMPeripheral, [CBMService]) -> ())?
    public var didReadRSSI: ((CBMPeripheral, NSNumber, Error?) -> ())?
    public var didDiscoverServices: ((CBMPeripheral, Error?) -> ())?
    public var didDiscoverIncludedServices: ((CBMPeripheral, CBMService, Error?) -> ())?
    public var didDiscoverCharacteristics: ((CBMPeripheral, CBMService, Error?) -> ())?
    public var didUpdateCharacteristicValue: ((CBMPeripheral, CBMCharacteristic, Error?) -> ())?
    public var didWriteCharacteristicValue: ((CBMPeripheral, CBMCharacteristic, Error?) -> ())?
    public var didUpdateNotificationState: ((CBMPeripheral, CBMCharacteristic, Error?) -> ())?
    public var didDiscoverDescriptors: ((CBMPeripheral, CBMCharacteristic, Error?) -> ())?
    public var didUpdateDescriptorValue: ((CBMPeripheral, CBMDescriptor, Error?) -> ())?
    public var didWriteDescriptorValue: ((CBMPeripheral, CBMDescriptor, Error?) -> ())?
    public var isReadyToSendWriteWithoutResponse: ((CBMPeripheral) -> ())?
    
    open func peripheralDidUpdateName(_ peripheral: CBMPeripheral) {
        didUpdateName?(peripheral)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didModifyServices invalidatedServices: [CBMService]) {
        didModifyServices?(peripheral, invalidatedServices)
    }
    
    open func peripheral(_ peripheral: CBMPeripheral,
                         didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadRSSI?(peripheral, RSSI, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didDiscoverServices error: Error?) {
        didDiscoverServices?(peripheral, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didDiscoverIncludedServicesFor service: CBMService, error: Error?) {
        didDiscoverIncludedServices?(peripheral, service, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didDiscoverCharacteristicsFor service: CBMService, error: Error?) {
        didDiscoverCharacteristics?(peripheral, service, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didUpdateValueFor characteristic: CBMCharacteristic, error: Error?) {
        didUpdateCharacteristicValue?(peripheral, characteristic, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didWriteValueFor characteristic: CBMCharacteristic, error: Error?) {
        didWriteCharacteristicValue?(peripheral, characteristic, error)
    }

    open func peripheral(_ peripheral: CBMPeripheral,
                         didUpdateNotificationStateFor characteristic: CBMCharacteristic, error: Error?) {
        didUpdateNotificationState?(peripheral, characteristic, error)
    }
    
    open func peripheral(_ peripheral: CBMPeripheral,
                         didDiscoverDescriptorsFor characteristic: CBMCharacteristic, error: Error?) {
        didDiscoverDescriptors?(peripheral, characteristic, error)
    }
    
    open func peripheral(_ peripheral: CBMPeripheral,
                         didUpdateValueFor descriptor: CBMDescriptor, error: Error?) {
        didUpdateDescriptorValue?(peripheral, descriptor, error)
    }
    
    open func peripheral(_ peripheral: CBMPeripheral,
                         didWriteValueFor descriptor: CBMDescriptor, error: Error?) {
        didWriteDescriptorValue?(peripheral, descriptor, error)
    }

    open func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBMPeripheral) {
        isReadyToSendWriteWithoutResponse?(peripheral)
    }
}

/// A helper class that allows setting delegate callbacks as closures.
///
/// This class differs from ``CBMPeripheralDelegateProxy`` that it also contains callbacks added in iOS 11.
///
/// - SeeAlso: ``CBMPeripheralDelegateProxy``
@available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
open class CBMPeripheralDelegateProxyWithL2CAPChannel: CBMPeripheralDelegateProxy {
    public var didOpenChannel: ((CBMPeripheral, CBML2CAPChannel?, Error?) -> ())?

    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    open func peripheral(_ peripheral: CBMPeripheral,
                         didOpen channel: CBML2CAPChannel?, error: Error?) {
        didOpenChannel?(peripheral, channel, error)
    }
}
