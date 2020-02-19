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

public class CBCentralManagerMock: CBCentralManagerType {
    public var mockDelegate: CBCentralManagerMockDelegate?
    
    public var delegate: CBCentralManagerDelegateType?
    
    fileprivate let queue: DispatchQueue
    
    public fileprivate(set) var state: CBManagerStateType
    public fileprivate(set) var isScanning: Bool
    
    public required init() {
        self.isScanning = false
        self.queue = DispatchQueue.main
        self.state = .poweredOn
    }
    
    public required init(delegate: CBCentralManagerDelegateType?, queue: DispatchQueue?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.state = .unknown
        self.delegate = delegate
    }
    
    public required init(delegate: CBCentralManagerDelegateType?, queue: DispatchQueue?, options: [String : Any]?) {
        self.isScanning = false
        self.queue = queue ?? DispatchQueue.main
        self.state = .unknown
        self.delegate = delegate
    }
    
    @available(iOS 13.0, *)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        return features.isSubset(of: .extendedScanAndConnect)
    }
    
    @objc func notify(timer: Timer) {
        guard let result = timer.userInfo as? MockDevice, isScanning else {
            timer.invalidate()
            return
        }
        let name = result.advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let peripheral = CBPeripheralMock(central: self, name: name)
        let RSSI: NSNumber = NSNumber(value: result.proximity.rawValue + Int.random(in: -40...40))
        delegate?.centralManager(self, didDiscover: peripheral,
                                      advertisementData: result.advertisementData,
                                      rssi: RSSI)
    }
    
    var timer: Timer?
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        guard !isScanning else {
            return
        }
        isScanning = true
        
        if let results = mockDelegate?.centralManager(self,
                                                      didStartScanningForPeripheralsWithServices: serviceUUIDs) {
            results.forEach { (result) in
                let services = result.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
                if serviceUUIDs == nil || services?.contains(where: serviceUUIDs!.contains) ?? false {
                    // The timer will be called multiple times if option was set.
                    let allowDuplicates = options?[CBCentralManagerScanOptionAllowDuplicatesKey] as? NSNumber ?? NSNumber(booleanLiteral: false)
                    Timer.scheduledTimer(timeInterval: result.advertisingInterval,
                                         target: self,
                                         selector: #selector(notify(timer:)),
                                         userInfo: result,
                                         repeats: allowDuplicates.boolValue)
                }
            }
        }
    }
    
    public func stopScan() {
        isScanning = false
    }
    
    public func connect(_ peripheral: CBPeripheralType, options: [String : Any]?) {
        if let mock = peripheral as? CBPeripheralMock,
            peripheral.state == .disconnected {
            mock.state = .connecting
            queue.asyncAfter(deadline: .now() + .milliseconds(30)) {
                mock.state = .connected
                self.delegate?.centralManager(self, didConnect: mock)
            }
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBPeripheralType) {
        if let mock = peripheral as? CBPeripheralMock,
            peripheral.state == .connected || peripheral.state == .connecting {
            if #available(iOS 9.0, *) {
                mock.state = .disconnecting
            }
            queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
                mock.state = .disconnected
                self.delegate?.centralManager(self, didConnect: mock)
            }
        }
    }
    
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralType] {
        // Not implemented
        return []
    }
    
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralType] {
        // Not implemented
        return []
    }
    
    @available(iOS 13.0, *)
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]?) {
        // Not implemented
    }
    
}

public class CBPeripheralMock: CBPeer, CBPeripheralMockType {
    public var delegate: CBPeripheralDelegateType?
    
    private let queue: DispatchQueue
    private let _identifier: UUID
    
    public override var identifier: UUID {
        return _identifier
    }
    
    public internal(set) var name: String?
    public internal(set) var state: CBPeripheralState = .disconnected
    public internal(set) var services: [CBService]? = nil
    public internal(set) var canSendWriteWithoutResponse: Bool = false
    public internal(set) var ancsAuthorized: Bool = false
    
    fileprivate init(central: CBCentralManagerMock, name: String?) {
        self.name = name
        self.queue = central.queue
        self._identifier = UUID()
    }
    
    private var _delegate: CBPeripheralDelegateType?
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) {
//        if serviceUUIDs?.contains(BlinkyPeripheral.nordicBlinkyServiceUUID) ?? true {
//            queue.asyncAfter(deadline: .now() + .milliseconds(40)) {
//                self.delegate?.peripheral(self, didDiscoverServices: nil)
//            }
//        }
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
//        if service == BlinkyPeripheral.nordicBlinkyServiceUUID {
//            queue.asyncAfter(deadline: .now() + .milliseconds(40)) {
//                self.delegate?.peripheral(self, didDiscoverCharacteristicsFor: service, error: nil)
//            }
//        }
    }
    
    public func discoverDescriptors(for characteristic: CBCharacteristic) {
        // TODO
    }
    
    public func readValue(for characteristic: CBCharacteristic) {
//        if characteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
//            queue.asyncAfter(deadline: .now() + .milliseconds(40)) {
//                self.delegate?.peripheral(self, didUpdateValueFor: characteristic, error: nil)
//            }
//        }
    }
    
    public func readValue(for descriptor: CBDescriptor) {
        // TODO
    }
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        // TODO
        return 0
    }
    
    public func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        // TODO
    }
    
    public func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        // TODO
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        // TODO
    }
    
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) {
        // TODO
    }
}
