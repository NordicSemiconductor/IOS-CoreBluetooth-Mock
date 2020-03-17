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
import CoreBluetoothMock

extension Notification.Name {

    static let newPeripheral = Notification.Name("New Peripheral")
    static let state         = Notification.Name("Central Manager State")

}

extension Notification {

    static func manager(_ manager: BlinkyManager, didDiscover blinky: BlinkyPeripheral) -> Notification {
        return Notification(name: .newPeripheral,
                            userInfo: ["blinky": blinky])
    }

    static func manager(_ manager: BlinkyManager, didChangeStateTo state: CBMManagerState) -> Notification {
        return Notification(name: .state, userInfo: ["state": state])
    }

}

extension BlinkyManager {

    func post(_ notification: Notification) {
        NotificationCenter.default.post(notification)
    }

    func dispose(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }

    private func on(_ name: Notification.Name, do action: @escaping (Notification) -> ()) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: action)
    }

    func onBlinkyDiscovery(do action: @escaping (BlinkyPeripheral) -> ()) -> NSObjectProtocol {
        return on(.newPeripheral) { notification in
            if let userInfo = notification.userInfo,
               let blinky = userInfo["blinky"] as? BlinkyPeripheral {
                action(blinky)
            }
        }
    }

    func onStateChange(do action: @escaping (CBMManagerState) -> ()) -> NSObjectProtocol {
        return on(.state) { notification in
            if let userInfo = notification.userInfo,
               let state = userInfo["state"] as? CBMManagerState {
                action(state)
            }
        }
    }

}
