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

import UIKit

class BlinkyPeripheral: NSObject, CBPeripheralDelegate {
    
    // MARK: - Blinky services and characteristics Identifiers
    
    public static let nordicBlinkyServiceUUID  = CBUUID(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let buttonCharacteristicUUID = CBUUID(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let ledCharacteristicUUID    = CBUUID(string: "00001525-1212-EFDE-1523-785FEABCD123")
    
    // MARK: - Properties

    private let blinkyManager                 : BlinkyManager
    let basePeripheral                        : CBPeripheral
    public private(set) var advertisedName    : String
    public private(set) var isConnectable     : Bool
    public private(set) var RSSI              : NSNumber
    
    // MARK: - Computed variables
    
    /// Whether the device is in connected state, or not.
    public var isConnected: Bool {
        return basePeripheral.state == .connected
    }

    // MARK: - Characteristic properties
    
    private var buttonCharacteristic: CBCharacteristic?
    private var ledCharacteristic   : CBCharacteristic?
    
    // MARK: - Public API

    var state: CBPeripheralState {
        return basePeripheral.state
    }
    
    /// Creates the BlinkyPeripheral based on the received peripheral and advertising data.
    /// The device name is obtained from the advertising data, instead of CBPeripheral's name
    /// property to avoid caching problems.
    /// - Parameters:
    ///   - peripheral: The underlying peripheral.
    ///   - data: The latest advertisement data of the device.
    ///   - currentRSSI: The most recent RSSI value.
    init(withPeripheral peripheral: CBPeripheral,
         advertisementData data: [String : Any],
         andRSSI currentRSSI: NSNumber,
         using manager: BlinkyManager) {
        self.blinkyManager = manager
        self.basePeripheral = peripheral
        self.RSSI = currentRSSI
        self.advertisedName = data[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device".localized
        self.isConnectable  = data[CBAdvertisementDataIsConnectable] as? Bool ?? false
        super.init()
        peripheral.delegate = self

        _ = manager.onStateChange { [weak self] state in
            if let self = self, state != .poweredOn {
                self.post(.blinkyDidDisconnect(self, error: nil))
            }
        }
        onConnected {
            self.discoverBlinkyServices()
        }
    }

    /// Connects to the Blinky device.
    func connect() {
        blinkyManager.connect(self)
    }

    /// Cancels existing or pending connection.
    func disconnect() {
        blinkyManager.disconnect(self)
    }
    
    // MARK: - Blinky API
    
    /// Reads value of LED Characteristic. If such characteristic was not
    /// found, this method does nothing. If it was found, but does not have
    /// read property, the delegate will be notified with isOn = false.
    public func readLEDValue() {
        if let ledCharacteristic = ledCharacteristic {
            if ledCharacteristic.properties.contains(.read) {
                print("Reading LED characteristic...")
                basePeripheral.readValue(for: ledCharacteristic)
            } else {
                print("Can't read LED state")
                post(.ledState(of: self, didChangeTo: nil))
            }
        }
    }
    
    /// Reads value of Button Characteristic. If such characteristic was not
    /// found, this method does nothing. If it was found, but does not have
    /// read property, the delegate will be notified with isPressed = false.
    public func readButtonValue() {
        if let buttonCharacteristic = buttonCharacteristic {
            if buttonCharacteristic.properties.contains(.read) {
                print("Reading Button characteristic...")
                basePeripheral.readValue(for: buttonCharacteristic)
            } else {
                print("Can't read Button state")
                post(.buttonState(of: self, didChangeTo: false))
            }
        }
    }
    
    /// Sends a request to turn the LED on.
    public func turnOnLED() {
        writeLEDCharacteristic(withValue: Data([0x1]))
    }
    
    /// Sends a request to turn the LED off.
    public func turnOffLED() {
        writeLEDCharacteristic(withValue: Data([0x0]))
    }
    
    // MARK: - Implementation
    
    /// Starts service discovery, only for LED Button Service.
    private func discoverBlinkyServices() {
        print("Discovering LED Button service...")
        basePeripheral.delegate = self
        basePeripheral.discoverServices([BlinkyPeripheral.nordicBlinkyServiceUUID])
    }
    
    /// Starts characteristic discovery for LED and Button Characteristics.
    /// - Parameter service: The instance of a service in which characteristics will
    ///                      be discovered.
    private func discoverCharacteristicsForBlinkyService(_ service: CBService) {
        print("Discovering LED and Button characteristics...")
        basePeripheral.discoverCharacteristics(
            [BlinkyPeripheral.buttonCharacteristicUUID, BlinkyPeripheral.ledCharacteristicUUID],
            for: service)
    }
    
    /// Enables notification for given characteristic.
    /// If the characteristic does not have notify property, this method will
    /// post blinkyDidConnect event and try to read values
    /// of LED and Button.
    /// - Parameter characteristic: Characteristic to be enabled.
    private func enableButtonNotifications() {
        if let buttonCharacteristic = buttonCharacteristic,
           buttonCharacteristic.properties.contains(.notify) {
            print("Enabling notifications for characteristic...")
            basePeripheral.setNotifyValue(true, for: buttonCharacteristic)
        } else {
            post(.blinky(self,
                    didBecameReadyWithLedSupported: ledCharacteristic != nil,
                    buttonSupported: buttonCharacteristic != nil)
            )
            readButtonValue()
            readLEDValue()
        }
    }
    
    /// Writes the value to the LED characteristic. Acceptable value
    /// is 1-byte long, with 0x00 to disable and 0x01 to enable the LED.
    /// If there is no LED characteristic, this method does nothing.
    /// If the characteristic does not have any of write properties
    /// this method also does nothing.
    /// - Parameter value: Data to be written to the LED characteristic.
    private func writeLEDCharacteristic(withValue value: Data) {
        if let ledCharacteristic = ledCharacteristic {
            if ledCharacteristic.properties.contains(.write) {
                print("Writing LED value (with response)...")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withResponse)
            } else if ledCharacteristic.properties.contains(.writeWithoutResponse) {
                print("Writing LED value... (without response)")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withoutResponse)
                // peripheral(_:didWriteValueFor,error) will not be called after write without response
                // we are calling the delegate here
                didWriteValueToLED(value)
            } else {
                print("LED Characteristic is not writable")
            }
        }
    }
    
    /// A callback called when the LED value has been written.
    /// - Parameter value: The data written.
    private func didWriteValueToLED(_ value: Data) {
        guard value.count == 1 else {
            return
        }
        print("LED value written \(value[0])")
        post(.ledState(of: self, didChangeTo: value[0] == 0x01))
    }
    
    /// A callback called when the Button characteristic value has changed.
    /// - Parameter value: The data received.
    private func didReceiveButtonNotification(withValue value: Data) {
        guard value.count == 1 else {
            return
        }
        print("Button value changed to: \(value[0])")
        post(.buttonState(of: self, didChangeTo: value[0] == 0x01))
    }
    
    // MARK: - NSObject protocols
    
    override func isEqual(_ object: Any?) -> Bool {
        if let peripheralObject = object as? BlinkyPeripheral {
            return peripheralObject.basePeripheral.identifier == basePeripheral.identifier
        }
        if let peripheralObject = object as? CBPeripheral {
            return peripheralObject.identifier == basePeripheral.identifier
        }
        return false
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        if peripheral.identifier == basePeripheral.identifier {
            if let error = error {
                print("Connection failed: \(error.localizedDescription)")
            } else {
                print("Connection failed: No error")
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("Reading value failed: \(error!.localizedDescription)")
            post(.blinkyDidFailToConnect(self, error: error))
            disconnect()
            return
        }
        if characteristic == buttonCharacteristic {
            if let value = characteristic.value {
                didReceiveButtonNotification(withValue: value)
            }
        } else if characteristic == ledCharacteristic {
            if let value = characteristic.value {
                didWriteValueToLED(value)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("Enabling notifications failed: \(error!.localizedDescription)")
            post(.blinkyDidFailToConnect(self, error: error))
            disconnect()
            return
        }
        if characteristic == buttonCharacteristic {
            #if swift(>=5.5)
            assert(characteristic.service?.isPrimary ?? false)
            assert(characteristic.service?.peripheral?.identifier == basePeripheral.identifier)
            #else
            assert(characteristic.service.isPrimary)
            assert(characteristic.service.peripheral.identifier == basePeripheral.identifier)
            #endif
            assert(characteristic.isNotifying)
            print("Button notifications enabled")
            post(.blinky(self,
                    didBecameReadyWithLedSupported: ledCharacteristic != nil,
                    buttonSupported: buttonCharacteristic != nil)
            )
            readButtonValue()
            readLEDValue()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Discovering services failed: \(error!.localizedDescription)")
            post(.blinkyDidFailToConnect(self, error: error))
            disconnect()
            return
        }
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BlinkyPeripheral.nordicBlinkyServiceUUID {
                    print("LED Button service found")
                    //Capture and discover all characteristics for the blinky service
                    assert(service.isPrimary)
                    assert(service.characteristics == nil)
                    #if swift(>=5.5)
                    assert(service.peripheral?.identifier == peripheral.identifier)
                    #else
                    assert(service.peripheral.identifier == peripheral.identifier)
                    #endif
                    discoverCharacteristicsForBlinkyService(service)
                    return
                }
            }
        }
        // Blinky service has not been found
        print("Device not supported: Required service not found.")
        post(.blinky(self,
                didBecameReadyWithLedSupported: false,
                buttonSupported: false)
        )
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Discovering characteristics failed: \(error!.localizedDescription)")
            post(.blinkyDidFailToConnect(self, error: error))
            disconnect()
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                assert(characteristic.service == service)
                if characteristic.uuid == BlinkyPeripheral.buttonCharacteristicUUID {
                    print("Button characteristic found")
                    buttonCharacteristic = characteristic
                } else if characteristic.uuid == BlinkyPeripheral.ledCharacteristicUUID {
                    print("LED characteristic found")
                    ledCharacteristic = characteristic
                }
            }
        }
        
        // If Button characteristic was found, try to enable notifications on it.
        if let _ = buttonCharacteristic {
            enableButtonNotifications()
        } else if let _ = ledCharacteristic {
            // else, notify the delegate and read LED state.
            post(.blinky(self,
                    didBecameReadyWithLedSupported: true,
                    buttonSupported: false)
            )
            readLEDValue()
        } else {
            print("Device not supported: Required characteristics not found.")
            post(.blinky(self,
                    didBecameReadyWithLedSupported: false,
                    buttonSupported: false)
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Writing value failed: \(error.localizedDescription)")
        }
        // LED value has been written, let's read it to confirm.
        if characteristic.properties.contains(.read) {
            readLEDValue()
        }
    }
}
