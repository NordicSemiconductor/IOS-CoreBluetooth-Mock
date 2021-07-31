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

class BlinkyManager {
    /// Underlying central manager.
    private var centralManager: CBCentralManager!
    /// A list of discovered peripherals.
    private(set) var discoveredPeripherals: [BlinkyPeripheral]
    /// The blinky peripheral that this manager is currently connecting or connected to.
    private var connectedBlinky: BlinkyPeripheral?

    var state: CBManagerState {
        return centralManager.state
    }

    init(_ mock: Bool) {
        discoveredPeripherals = []
        centralManager = CBCentralManagerFactory.instance(
                delegate: self,
                queue: nil,
                options: [CBCentralManagerOptionShowPowerAlertKey : true],
                forceMock: mock
        )
    }

    func startScan() -> Bool {
        guard centralManager.state == .poweredOn else {
            return false
        }
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(
                    withServices: [BlinkyPeripheral.nordicBlinkyServiceUUID],
                    options: [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            )
        }
        return true
    }

    func stopScan() {
        centralManager.stopScan()
    }

    func reset() {
        discoveredPeripherals.removeAll()
    }

    var isEmpty: Bool {
        return discoveredPeripherals.isEmpty
    }

    /// Connects to the Blinky device.
    func connect(_ blinky: BlinkyPeripheral) {
        guard state == .poweredOn, connectedBlinky == nil else {
            return
        }
        connectedBlinky = blinky
        print("Connecting to Blinky device...")
        centralManager.connect(blinky.basePeripheral)
    }

    /// Cancels existing or pending connection.
    func disconnect(_ blinky: BlinkyPeripheral) {
        guard state == .poweredOn else {
            return
        }
        guard blinky.state != .disconnected else {
            connectedBlinky = nil
            return
        }
        print("Cancelling connection...")
        centralManager.cancelPeripheralConnection(blinky.basePeripheral)
    }

}

extension BlinkyManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager state changed to \(central.state)")
        if central.state != .poweredOn {
            connectedBlinky = nil
        }
        post(.manager(self, didChangeStateTo: central.state))
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let blinky = BlinkyPeripheral(
                withPeripheral: peripheral,
                advertisementData: advertisementData,
                andRSSI: RSSI,
                using: self
        )
        if !discoveredPeripherals.contains(blinky) {
            discoveredPeripherals.append(blinky)
        }
        post(.manager(self, didDiscover: blinky))
    }

    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        if let blinky = connectedBlinky,
           blinky.basePeripheral.identifier == peripheral.identifier {
            print("Blinky connected")
            blinky.post(.blinkyDidConnect(blinky))
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        if let blinky = connectedBlinky,
           blinky.basePeripheral.identifier == peripheral.identifier {
            if let error = error {
                print("Connection failed: \(error)")
            } else {
                print("Connection failed: No error")
            }
            connectedBlinky = nil
            blinky.post(.blinkyDidFailToConnect(blinky, error: error))
        }
    }

    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        if let blinky = connectedBlinky,
           blinky.basePeripheral.identifier == peripheral.identifier {
            print("Blinky disconnected")
            connectedBlinky = nil
            blinky.post(.blinkyDidDisconnect(blinky, error: error))
        }
    }
}
