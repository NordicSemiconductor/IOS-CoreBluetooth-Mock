//
//  CBPeripheralDelegateType.swift
//  CoreBluetoothMock
//
//  Created by Aleksander Nowakowski on 18/02/2020.
//

import Foundation
import CoreBluetooth

public protocol CBPeripheralDelegateType: class {

    func peripheralDidUpdateName(_ peripheral: CBPeripheralType)
    
    @available(iOS 7.0, *)
    func peripheral(_ peripheral: CBPeripheralType,
                    didModifyServices invalidatedServices: [CBService])
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didReadRSSI RSSI: NSNumber, error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverServices error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverIncludedServicesFor service: CBService, error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?)

    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didWriteValueFor descriptor: CBDescriptor, error: Error?)

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheralType)

    @available(iOS 11.0, *)
    func peripheral(_ peripheral: CBPeripheralType,
                    didOpen channel: CBL2CAPChannel?, error: Error?)
}

public extension CBPeripheralDelegateType {
    
    func peripheralDidUpdateName(_ p: CBPeripheralType) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didModifyServices invalidatedServices: [CBService]) {
        // optional method
    }
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didReadRSSI RSSI: NSNumber, error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverServices error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // optional method
    }

    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // optional method
    }
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        // optional method
    }
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        // optional method
    }
    
    func peripheral(_ peripheral: CBPeripheralType,
                    didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        // optional method
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheralType) {
        // optional method
    }

    @available(iOS 11.0, *)
    func peripheral(_ peripheral: CBPeripheralType,
                    didOpen channel: CBL2CAPChannel?, error: Error?) {
        // optional method
    }
}
