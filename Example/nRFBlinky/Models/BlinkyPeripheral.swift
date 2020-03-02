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
import CoreBluetooth
import CoreBluetoothMock

protocol BlinkyDelegate {
    
    /// A callback called when a device gets connected.
    /// - Parameters:
    ///   - ledSupported: A flag indicating that the LED Service is present on the
    ///                   device.
    ///   - buttonSupported: A flag indicating that the Button Service is present
    ///                      on the device.
    func blinkyDidConnect(ledSupported: Bool, buttonSupported: Bool)
    
    /// A callback called when the device gets disconnected.
    func blinkyDidDisconnect()
    
    /// A callback called after a notification with new button state has been received.
    /// - Parameter isPressed: The new button state.
    func buttonStateChanged(isPressed: Bool)
    
    /// A callback called when the request to turn on or off the LED has been sent.
    /// - Parameter isOn: The new LED state.
    func ledStateChanged(isOn: Bool)
}

class BlinkyPeripheral: NSObject, CBMPeripheralDelegate, CBMCentralManagerDelegate {
    
    // MARK: - Blinky services and charcteristics Identifiers
    
    public static let nordicBlinkyServiceUUID  = CBUUID(string: "00001523-1212-EFDE-1523-785FEABCD123")
    public static let buttonCharacteristicUUID = CBUUID(string: "00001524-1212-EFDE-1523-785FEABCD123")
    public static let ledCharacteristicUUID    = CBUUID(string: "00001525-1212-EFDE-1523-785FEABCD123")
    
    // MARK: - Properties
    
    private let centralManager                : CBMCentralManager
    private let basePeripheral                : CBMPeripheral
    public private(set) var advertisedName    : String?
    public private(set) var RSSI              : NSNumber
    
    public var delegate: BlinkyDelegate?
    
    // MARK: - Computed variables
    
    /// Whether the device is in connected state, or not.
    public var isConnected: Bool {
        return basePeripheral.state == .connected
    }

    // MARK: - Characteristic properties
    
    private var buttonCharacteristic: CBMCharacteristic?
    private var ledCharacteristic   : CBMCharacteristic?
    
    // MARK: - Public API
    
    /// Creates teh BlinkyPeripheral based on the received peripheral and advertisign data.
    /// The device name is obtaied from the advertising data, not from CBPeripheral object
    /// to avoid caching problems.
    init(withPeripheral peripheral: CBMPeripheral,
         advertisementData advertisementDictionary: [String : Any],
         andRSSI currentRSSI: NSNumber, using manager: CBMCentralManager) {
        centralManager = manager
        basePeripheral = peripheral
        RSSI = currentRSSI
        super.init()
        advertisedName = parseAdvertisementData(advertisementDictionary)
        basePeripheral.delegate = self
    }
    
    /// Connects to the Blinky device.
    public func connect() {
        guard centralManager.state == .poweredOn else {
            delegate?.blinkyDidDisconnect()
            return
        }
        centralManager.delegate = self
        print("Connecting to Blinky device...")
        centralManager.connect(basePeripheral, options: nil)
    }
    
    /// Cancels existing or pending connection.
    public func disconnect() {
        if basePeripheral.state != .disconnected {
            print("Cancelling connection...")
            centralManager.cancelPeripheralConnection(basePeripheral)
        }
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
                delegate?.ledStateChanged(isOn: false)
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
                delegate?.buttonStateChanged(isPressed: false)
            }
        }
    }
    
    /// Sends a request to turn the LED on.
    public func turnOnLED() {
        writeLEDCharcateristic(withValue: Data([0x1]))
    }
    
    /// Sends a request to turn the LED off.
    public func turnOffLED() {
        writeLEDCharcateristic(withValue: Data([0x0]))
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
    private func discoverCharacteristicsForBlinkyService(_ service: CBMService) {
        print("Discovering LED and Button characteristrics...")
        basePeripheral.discoverCharacteristics(
            [BlinkyPeripheral.buttonCharacteristicUUID, BlinkyPeripheral.ledCharacteristicUUID],
            for: service)
    }
    
    /// Enables notification for given characteristic.
    /// If the characteristic does not have notify property, this method will
    /// call delegate's blinkyDidConnect method and try to read values
    /// of LED and Button.
    /// - Parameter characteristic: Characteristic to be enabled.
    private func enableNotifications(for characteristic: CBMCharacteristic) {
        if characteristic.properties.contains(.notify) {
            print("Enabling notifications for characteristic...")
            basePeripheral.setNotifyValue(true, for: characteristic)
        } else {
            delegate?.blinkyDidConnect(ledSupported: ledCharacteristic != nil, buttonSupported: true)
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
    private func writeLEDCharcateristic(withValue value: Data) {
        if let ledCharacteristic = ledCharacteristic {
            if ledCharacteristic.properties.contains(.write) {
                print("Writing LED value (with response)...")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withResponse)
            } else if ledCharacteristic.properties.contains(.writeWithoutResponse) {
                print("Writing LED value... (without response)")
                basePeripheral.writeValue(value, for: ledCharacteristic, type: .withoutResponse)
                // peripheral(_:didWriteValueFor,error) will not be called after write without response
                // we are caling the delegate here
                didWriteValueToLED(value)
            } else {
                print("LED Characteristic is not writable")
            }
        }
    }
    
    /// A callback called when the LED value has been written.
    /// - Parameter value: The data written.
    private func didWriteValueToLED(_ value: Data) {
        print("LED value written \(value[0])")
        delegate?.ledStateChanged(isOn: value[0] == 0x1)
    }
    
    /// A callback called when the Button characteristic value has changed.
    /// - Parameter value: The data received.
    private func didReceiveButtonNotification(withValue value: Data) {
        print("Button value changed to: \(value[0])")
        delegate?.buttonStateChanged(isPressed: value[0] == 0x1)
    }
    
    /// This method parses the advertising data and returns the device name
    /// found in Complete or Shortened Local Name field.
    /// - Parameter data: The advertising data of the device.
    /// - Returns: The device name or "Unknown Device" when not found.
    private func parseAdvertisementData(_ data: [String : Any]) -> String {
        if let name = data[CBAdvertisementDataLocalNameKey] as? String {
            return name
        } else {
            return "Unknown Device".localized
        }
    }
    
    // MARK: - NSObject protocols
    
    override func isEqual(_ object: Any?) -> Bool {
        if object is BlinkyPeripheral {
            let peripheralObject = object as! BlinkyPeripheral
            return peripheralObject.basePeripheral.identifier == basePeripheral.identifier
        } else if object is CBMPeripheralMock {
            let peripheralObject = object as! CBMPeripheralMock
            return peripheralObject.identifier == basePeripheral.identifier
        } else {
            return false
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBMCentralManager) {
        if central.state != .poweredOn {
            print("Central Manager state changed to \(central.state)")
            delegate?.blinkyDidDisconnect()
        }
    }
    
    func centralManager(_ central: CBMCentralManager, didConnect peripheral: CBMPeripheral) {
        if peripheral.identifier == basePeripheral.identifier {
            print("Connected to Blinky")
            discoverBlinkyServices()
        }
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didFailToConnect peripheral: CBMPeripheral,
                        error: Error?) {
        if peripheral.identifier == basePeripheral.identifier {
            if let error = error {
                print("Connection failed: \(error)")
            } else {
                print("Connection failed: No error")
            }
        }
    }
    
    func centralManager(_ central: CBMCentralManager,
                        didDisconnectPeripheral peripheral: CBMPeripheral,
                        error: Error?) {
        if peripheral.identifier == basePeripheral.identifier {
            print("Blinky disconnected")
            delegate?.blinkyDidDisconnect()
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBMPeripheral,
                    didUpdateValueFor characteristic: CBMCharacteristic,
                    error: Error?) {
        guard error == nil else {
            print("Operation failed: \(error!)")
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

    func peripheral(_ peripheral: CBMPeripheral,
                    didUpdateNotificationStateFor characteristic: CBMCharacteristic,
                    error: Error?) {
        if characteristic == buttonCharacteristic {
            assert(characteristic.service.isPrimary)
            assert(characteristic.service.peripheral.identifier == basePeripheral.identifier)
            assert(characteristic.isNotifying)
            print("Button notifications enabled")
            delegate?.blinkyDidConnect(ledSupported: ledCharacteristic != nil, buttonSupported: buttonCharacteristic != nil)
            readButtonValue()
            readLEDValue()
        }
    }

    func peripheral(_ peripheral: CBMPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BlinkyPeripheral.nordicBlinkyServiceUUID {
                    print("LED Button service found")
                    //Capture and discover all characteristics for the blinky service
                    assert(service.isPrimary)
                    assert(service.characteristics == nil)
                    assert(service.peripheral.identifier == peripheral.identifier)
                    discoverCharacteristicsForBlinkyService(service)
                    return
                }
            }
        }
        // Blinky service has not been found
        print("Device not supported: Required service not found.")
        delegate?.blinkyDidConnect(ledSupported: false, buttonSupported: false)
    }
    
    func peripheral(_ peripheral: CBMPeripheral,
                    didDiscoverCharacteristicsFor service: CBMService, error: Error?) {
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
        
        // If Button caracteristic was found, try to enable notifications on it.
        if let buttonCharacteristic = buttonCharacteristic {
            enableNotifications(for: buttonCharacteristic)
        } else if let _ = ledCharacteristic {
            // else, notify the delegate and read LED state.
            delegate?.blinkyDidConnect(ledSupported: true, buttonSupported: false)
            readLEDValue()
        } else {
            print("Device not supported: Required characteristics not found.")
            delegate?.blinkyDidConnect(ledSupported: false, buttonSupported: false)
        }
    }
    
    func peripheral(_ peripheral: CBMPeripheral,
                    didWriteValueFor characteristic: CBMCharacteristic, error: Error?) {
        // LED value has been written, let's read it to confirm.
        readLEDValue()
    }
}
