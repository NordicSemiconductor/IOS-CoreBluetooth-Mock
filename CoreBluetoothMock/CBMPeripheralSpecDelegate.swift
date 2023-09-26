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

/// This delegate should implement the behavior of a real Bluetooth LE device duting a connection.
public protocol CBMPeripheralSpecDelegate {

    /// This method is called when the mock peripheral has been reset.
    /// It should reset all values to the initial state.
    func reset()

    /// This method will be called when a connect request was initiated from a
    /// mock central manager.
    /// - Parameter peripheral: The peripheral specification to handle connection.
    /// - Returns: Success or an error. The error will be returned using
    ///            ``CBMCentralManagerDelegate/centralManager(_:didFailToConnect:error:)-2h1bb``.
    func peripheralDidReceiveConnectionRequest(_ peripheral: CBMPeripheralSpec)
        -> Result<Void, Error>

    /// This method will be called when disconnection was initiated from a
    /// mock central manager or peripheral side.
    /// - Parameters:
    ///   - peripheral: The peripheral specification that is disconnected.
    ///   - error: An optional reason of disconnection, in case it was initiated
    ///            from the peripheral side.
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: Error?)

    /// This method will be called when service discovery was initiated using a
    /// mock central manager. When success is returned, the services will be
    /// returned automatically based on the device specification.
    /// - Parameters:
    ///   - peripheral: The target device.
    ///   - serviceUUIDs: Optional services requested.
    /// - Returns: Success, or a service discovery error. The error will be reported
    ///            using ``CBMPeripheralDelegate/peripheral(_:didDiscoverServices:)-6mi4k``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBMUUID]?)
        -> Result<Void, Error>

    /// This method will be called when service discovery of included services was
    /// initiated using a mock central manager. When success is returned, the services
    /// will be returned automatically based on the device specification.
    /// - Parameters:
    ///   - peripheral: The target device.
    ///   - serviceUUIDs: Optional services requested.
    ///   - service: The primary service.
    /// - Returns: Success, or a service discovery error. The error will be reported
    ///            using ``CBMPeripheralDelegate/peripheral(_:didDiscoverIncludedServicesFor:error:)-6b62q``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBMUUID]?,
                    for service: CBMServiceMock)
        -> Result<Void, Error>

    /// This method will be called when characteristic discovery was initiated using a
    /// mock central manager. When success is returned, the characteristics will be returned
    /// automatically based on the device specification.
    /// - Parameters:
    ///   - peripheral: The target device.
    ///   - characteristicUUIDs: Optional characteristics requested.
    ///   - service: The parent service.
    /// - Returns: Success, or a service discovery error. The error will be reported
    ///            using ``CBMPeripheralDelegate/peripheral(_:didDiscoverCharacteristicsFor:error:)-2pyjk``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBMUUID]?,
                    for service: CBMServiceMock)
        -> Result<Void, Error>

    /// This method will be called when descriptor discovery was initiated using a
    /// mock central manager. When success is returned, the descriptors will be returned
    /// automatically based on the device specification.
    /// - Parameters:
    ///   - peripheral: The target device.
    ///   - characteristic: The parent characteristic.
    /// - Returns: Success, or a service discovery error. The error will be reported
    ///            using ``CBMPeripheralDelegate/peripheral(_:didDiscoverDescriptorsFor:error:)-240qo``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBMCharacteristicMock)
        -> Result<Void, Error>
    
    /// This method will be called when read request has been initiated from a mock
    /// central manager.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - characteristic: The characteristic, which value should be returned.
    /// - Returns: When success, the characteristic value should be returned. In case
    ///            of a failure, the returned error will be returned to the
    ///            ``CBMPeripheralDelegate/peripheral(_:didUpdateValueFor:error:)-2xce0``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
        -> Result<Data, Error>
    
    /// This method will be called when read request has been initiated from a mock
    /// central manager.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - descriptor: The descriptor, which value should be returned.
    /// - Returns: When success, the descriptor value should be returned. In case
    ///            of a failure, the returned error will be returned to the
    ///            ``CBMPeripheralDelegate/peripheral(_:didUpdateValueFor:error:)-2xce0``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor descriptor: CBMDescriptorMock)
        -> Result<Data, Error>
    
    /// This method will be called when write request has been initiated from a mock
    /// central manager.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - characteristic: The target characteristic.
    ///   - data: The data written.
    /// - Returns: Success, or the reason of failure. The returned error will be
    ///            returned to the ``CBMPeripheralDelegate/peripheral(_:didWriteValueFor:error:)-86kdv``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data)
        -> Result<Void, Error>
    
    /// This method will be called when write command has been initiated from a mock
    /// central manager. Write command is also known as write without response.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - characteristic: The target characteristic.
    ///   - data: The data written.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteCommandFor characteristic: CBMCharacteristicMock,
                    data: Data)
    
    /// This method will be called when write request has been initiated from a mock
    /// central manager.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - descriptor: The target descriptor.
    ///   - data: The data written.
    /// - Returns: Success, or the reason of failure. The returned error will be
    ///            returned to the ``CBMPeripheralDelegate/peripheral(_:didWriteValueFor:error:)-90cp``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor descriptor: CBMDescriptorMock,
                    data: Data)
        -> Result<Void, Error>
    
    /// This method will be called when client requested enabling or disabling notifications or
    /// indications on the given characteristic using a mock central manager.
    ///
    /// Value updates initiated from this method using ``CBMPeripheralSpec/simulateValueUpdate(_:for:)``
    /// will be ignored until
    ///  ``CBMPeripheralSpecDelegate/peripheral(_:didUpdateNotificationStateFor:error:)-4aash``
    /// is received.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - enabled: Whether notifications or indications were enabled or disabled.
    ///   - characteristic: The target characteristic.
    /// - Returns: Success, or the reason of a failure.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBMCharacteristicMock)
        -> Result<Void, Error>
    
    /// This method will be called when notifications or indications were enabled
    /// or disabled on the given characteristic using a mock central manager.
    ///
    /// It is safe to send value updates using
    /// ``CBMPeripheralSpec/simulateValueUpdate(_:for:)`` from this method if
    /// ``CBMCharacteristic/isNotifying`` is `true`.
    /// - Parameters:
    ///   - peripheral: The target peripheral specification.
    ///   - characteristic: The target characteristic.
    ///   - error: Error returned from
    ///            ``peripheral(_:didReceiveSetNotifyRequest:for:)-9r03q``.
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didUpdateNotificationStateFor characteristic: CBMCharacteristicMock,
                    error: Error?)
}

public extension CBMPeripheralSpecDelegate {

    func reset() {
        // Empty default implementation
    }

    func peripheralDidReceiveConnectionRequest(_ peripheral: CBMPeripheralSpec)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: Error?) {
        assert(peripheral.virtualConnections == 0)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBMUUID]?)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBMUUID]?,
                    for service: CBMService)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBMUUID]?,
                    for service: CBMServiceMock)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveIncludedServiceDiscoveryRequest: serviceUUIDs, for: service as CBMService)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBMUUID]?,
                    for service: CBMService)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBMUUID]?,
                    for service: CBMServiceMock)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveCharacteristicsDiscoveryRequest: characteristicUUIDs, for: service as CBMService)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBMCharacteristic)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBMCharacteristicMock)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveDescriptorsDiscoveryRequestFor: characteristic as CBMCharacteristic)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristic)
        -> Result<Data, Error> {
            return .failure(CBMATTError(.readNotPermitted))
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristicMock)
        -> Result<Data, Error> {
            return peripheral(p, didReceiveReadRequestFor: characteristic as CBMCharacteristic)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor descriptor: CBMDescriptor)
        -> Result<Data, Error> {
            return .failure(CBMATTError(.readNotPermitted))
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveReadRequestFor descriptor: CBMDescriptorMock)
        -> Result<Data, Error> {
            return peripheral(p, didReceiveReadRequestFor: descriptor as CBMDescriptor)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristic,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBMATTError(.writeNotPermitted))
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristicMock,
                    data: Data)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveWriteRequestFor: characteristic as CBMCharacteristic, data: data)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteCommandFor characteristic: CBMCharacteristic,
                    data: Data) {
        // Empty default implementation
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveWriteCommandFor characteristic: CBMCharacteristicMock,
                    data: Data) {
        peripheral(p, didReceiveWriteCommandFor: characteristic as CBMCharacteristic, data: data)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor descriptor: CBMDescriptor,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBATTError(.writeNotPermitted))
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveWriteRequestFor descriptor: CBMDescriptorMock,
                    data: Data)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveWriteRequestFor: descriptor as CBMDescriptor, data: data)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBMCharacteristic)
        -> Result<Void, Error> {
            if !characteristic.properties
                .isDisjoint(with: [
                    .notify,
                    .indicate,
                    .notifyEncryptionRequired,
                    .indicateEncryptionRequired]) {
                return .success(())
            } else {
                return .failure(CBMError(.invalidHandle))
            }
    }
    
    func peripheral(_ p: CBMPeripheralSpec,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBMCharacteristicMock)
        -> Result<Void, Error> {
            return peripheral(p, didReceiveSetNotifyRequest: enabled, for: characteristic as CBMCharacteristic)
    }
  
    func peripheral(_ p: CBMPeripheralSpec,
                    didUpdateNotificationStateFor characteristic: CBMCharacteristicMock,
                    error: Error?) {
        // Empty default implementation
    }

}
