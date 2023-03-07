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

extension Notification.Name {

    static let connection    = Notification.Name("Connection")
    static let ready         = Notification.Name("Ready")
    static let fail          = Notification.Name("Fail")
    static let disconnection = Notification.Name("Disconnection")
    static let ledState      = Notification.Name("LED State")
    static let buttonState   = Notification.Name("Button State")

}

extension Notification {

    static func blinkyDidConnect(_ blinkyPeripheral: BlinkyPeripheral) -> Notification {
        return Notification(name: .connection, object: blinkyPeripheral)
    }

    static func blinky(_ blinkyPeripheral: BlinkyPeripheral,
                       didBecameReadyWithLedSupported ledSupported: Bool,
                       buttonSupported: Bool) -> Notification {
        return Notification(name: .ready, object: blinkyPeripheral,
                            userInfo: ["ledSupported": ledSupported,
                                       "buttonSupported": buttonSupported])
    }
    
    static func blinkyDidFailToConnect(_ blinkyPeripheral: BlinkyPeripheral,
                                       error: Error?) -> Notification {
        return Notification(name: .fail, object: blinkyPeripheral,
                            userInfo: ["error": error as AnyObject])
    }

    static func blinkyDidDisconnect(_ blinkyPeripheral: BlinkyPeripheral,
                                    error: Error?) -> Notification {
        return Notification(name: .disconnection, object: blinkyPeripheral,
                            userInfo: ["error": error as AnyObject])
    }

    static func ledState(of blinkyPeripheral: BlinkyPeripheral,
                         didChangeTo isOn: Bool?) -> Notification {
        return Notification(name: .ledState, object: blinkyPeripheral,
                            userInfo: isOn.map { ["isOn": $0] } ?? nil )
    }

    static func buttonState(of blinkyPeripheral: BlinkyPeripheral,
                            didChangeTo isPressed: Bool?) -> Notification {
        return Notification(name: .buttonState, object: blinkyPeripheral,
                            userInfo: isPressed.map { ["isPressed": $0] } ?? nil)
    }

}

extension BlinkyPeripheral {

    func post(_ notification: Notification) {
        NotificationCenter.default.post(notification)
    }

    func dispose(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }

    private func on(_ name: Notification.Name, do action: @escaping (Notification) -> ()) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: self, queue: OperationQueue.main, using: action)
    }

    func onConnected(do action: @escaping () -> ()) {
        var observer: NSObjectProtocol?
        observer = on(.connection) { [unowned self] notification in
            self.dispose(observer!)
            action()
        }
    }

    func onReady(do action: @escaping (Bool, Bool) -> ()) {
        var observer: NSObjectProtocol?
        observer = on(.ready) { [unowned self] notification in
            self.dispose(observer!)
            if let userInfo = notification.userInfo,
               let ledSupported = userInfo["ledSupported"] as? Bool,
               let buttonSupported = userInfo["buttonSupported"] as? Bool {
                action(ledSupported, buttonSupported)
            }
        }
    }
    
    func onConnectionError(do action: @escaping (Error?) -> ()) {
        var observer: NSObjectProtocol?
        observer = on(.fail) { [unowned self] notification in
            self.dispose(observer!)
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? Error? {
                action(error)
            }
        }
    }

    func onDisconnected(do action: @escaping (Error?) -> ()) {
        var observer: NSObjectProtocol?
        observer = on(.disconnection) { [unowned self] notification in
            self.dispose(observer!)
            if let userInfo = notification.userInfo,
               let error = userInfo["error"] as? Error {
                action(error)
            } else {
                action(nil)
            }
        }
    }

    func onLedStateDidChange(do action: @escaping (Bool?) -> ()) -> NSObjectProtocol {
        return on(.ledState) { notification in
            if let userInfo = notification.userInfo {
                let isOn = userInfo["isOn"] as? Bool
                action(isOn)
            }
        }
    }

    func onButtonStateDidChange(do action: @escaping (Bool?) -> ()) -> NSObjectProtocol {
        return on(.buttonState) { notification in
            if let userInfo = notification.userInfo {
                let isPressed = userInfo["isPressed"] as? Bool
                action(isPressed)
            }
        }
    }

}
