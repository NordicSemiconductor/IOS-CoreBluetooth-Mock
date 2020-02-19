//
//  CBCentralManagerMockDelegate.swift
//  CoreBluetoothMock
//
//  Created by Aleksander Nowakowski on 18/02/2020.
//

import Foundation
import CoreBluetooth

public enum MockProximity: Int {
    /// The device will have RSSI values around -40 dBm.
    case near = -40
    /// The device will have RSSI values around -70 dBm.
    case immediate = -60
    /// The device is far, will have RSSI values around -100 dBm.
    case far = -100
}

public struct MockDevice {
    let advertisementData: [String : Any]
    let advertisingInterval: TimeInterval
    let proximity: MockProximity
    
    public init(advertisementData: [String : Any],
                advertisingInterval: TimeInterval,
                proximity: MockProximity) {
        self.advertisementData = advertisementData
        self.advertisingInterval = advertisingInterval
        self.proximity = proximity
    }
}

public protocol CBCentralManagerMockDelegate: class {
    
    func centralManager(_ central: CBCentralManagerMock,
                        didStartScanningForPeripheralsWithServices serviceUUIDs: [CBUUID]?) -> [MockDevice]
    
}
