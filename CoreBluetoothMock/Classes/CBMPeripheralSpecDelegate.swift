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

public protocol CBMPeripheralSpecDelegate {
    
    func peripheralDidReceiveConnectionRequest(_ peripheral: CBMPeripheralSpec)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: Error?)
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBUUID]?)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBUUID]?,
                    for service: CBMService)
        -> Result<Void, Error>
        
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBUUID]?,
                    for service: CBMService)
        -> Result<Void, Error>
            
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBMCharacteristic)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristic)
        -> Result<Data, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor descriptor: CBMDescriptor)
        -> Result<Data, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristic,
                    data: Data)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteCommandFor characteristic: CBMCharacteristic,
                    data: Data)
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor descriptor: CBMDescriptor,
                    data: Data)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBMCharacteristic)
        -> Result<Void, Error>
}

public extension CBMPeripheralSpecDelegate {
    
    func peripheralDidReceiveConnectionRequest(_ peripheral: CBMPeripheralSpec)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec, didDisconnect error: Error?) {
        // Empty default implementation
        assert(peripheral.virtualConnections == 0)
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBUUID]?)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBUUID]?,
                    for service: CBMService)
        -> Result<Void, Error> {
            return .success(())
    }
        
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBUUID]?,
                    for service: CBMService)
        -> Result<Void, Error> {
            return .success(())
   }
            
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBMCharacteristic)
        -> Result<Void, Error> {
            return .success(())
   }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor characteristic: CBMCharacteristic)
        -> Result<Data, Error> {
            return .failure(CBATTError(.readNotPermitted))
   }
        
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveReadRequestFor descriptor: CBMDescriptor)
        -> Result<Data, Error> {
            return .failure(CBATTError(.readNotPermitted))
    }

    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor characteristic: CBMCharacteristic,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBATTError(.writeNotPermitted))
    }

    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteCommandFor characteristic: CBMCharacteristic,
                    data: Data) {
        // Empty default implementation
    }

    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveWriteRequestFor descriptor: CBMDescriptor,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBATTError(.writeNotPermitted))
    }
    
    func peripheral(_ peripheral: CBMPeripheralSpec,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBMCharacteristic)
        -> Result<Void, Error> {
            if !characteristic.properties.isDisjoint(with: [.notify, .indicate, .notifyEncryptionRequired, .indicateEncryptionRequired]) {
                return .success(())
            } else {
                return .failure(CBError(.invalidHandle))
            }
    }
}
