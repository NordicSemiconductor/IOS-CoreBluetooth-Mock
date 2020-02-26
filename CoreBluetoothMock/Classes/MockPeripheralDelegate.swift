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

public protocol MockPeripheralDelegate {
    
    func peripheralDidReceiveConnectionRequest(_ peripheral: MockPeripheral)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: MockPeripheral, didDisconnect error: Error?)
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBUUID]?)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBUUID]?,
                    for service: CBServiceType)
        -> Result<Void, Error>
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBUUID]?,
                    for service: CBServiceType)
        -> Result<Void, Error>
            
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBCharacteristicType)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveReadRequestFor characteristic: CBCharacteristicType)
        -> Result<Data, Error>
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveReadRequestFor descriptor: CBDescriptorType)
        -> Result<Data, Error>
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteRequestFor characteristic: CBCharacteristicType,
                    data: Data)
        -> Result<Void, Error>
            
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteCommandFor characteristic: CBCharacteristicType,
                    data: Data)
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteRequestFor descriptor: CBDescriptorType,
                    data: Data)
        -> Result<Void, Error>
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBCharacteristicType)
        -> Result<Void, Error>
}

public extension MockPeripheralDelegate {
    
    func peripheralDidReceiveConnectionRequest(_ peripheral: MockPeripheral)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: MockPeripheral, didDisconnect error: Error?) {
        // Empty default implementation
        assert(peripheral.virtualConnections == 0)
    }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveServiceDiscoveryRequest serviceUUIDs: [CBUUID]?)
        -> Result<Void, Error> {
            return .success(())
    }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveIncludedServiceDiscoveryRequest serviceUUIDs: [CBUUID]?,
                    for service: CBServiceType)
        -> Result<Void, Error> {
            return .success(())
    }
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveCharacteristicsDiscoveryRequest characteristicUUIDs: [CBUUID]?,
                    for service: CBServiceType)
        -> Result<Void, Error> {
            return .success(())
   }
            
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveDescriptorsDiscoveryRequestFor characteristic: CBCharacteristicType)
        -> Result<Void, Error> {
            return .success(())
   }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveReadRequestFor characteristic: CBCharacteristicType)
        -> Result<Data, Error> {
            return .failure(CBATTError(.readNotPermitted))
   }
        
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveReadRequestFor descriptor: CBDescriptorType)
        -> Result<Data, Error> {
            return .failure(CBATTError(.readNotPermitted))
    }

    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteRequestFor characteristic: CBCharacteristicType,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBATTError(.writeNotPermitted))
    }

    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteCommandFor characteristic: CBCharacteristicType,
                    data: Data) {
        // Empty default implementation
    }

    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveWriteRequestFor descriptor: CBDescriptorType,
                    data: Data)
        -> Result<Void, Error> {
            return .failure(CBATTError(.writeNotPermitted))
    }
    
    func peripheral(_ peripheral: MockPeripheral,
                    didReceiveSetNotifyRequest enabled: Bool,
                    for characteristic: CBCharacteristicType)
        -> Result<Void, Error> {
            return .success(())
    }
}
