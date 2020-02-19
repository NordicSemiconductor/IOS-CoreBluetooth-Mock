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

class BlinkyTableViewCell: UITableViewCell {
    
    //MARK: - Outlets and Actions
    
    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var peripheralRSSIIcon: UIImageView!
    
    // MARK: - Properties
    
    static let reuseIdentifier = "blinkyPeripheralCell"
    
    private var lastUpdateTimestamp = Date()
    
    // MARK: - Implementation

    public func setupView(withPeripheral aPeripheral: BlinkyPeripheral) {
        peripheralName.text = aPeripheral.advertisedName

        if aPeripheral.RSSI.decimalValue < -60 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_2")
        } else if aPeripheral.RSSI.decimalValue < -50 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_3")
        } else if aPeripheral.RSSI.decimalValue < -30 {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_4")
        } else {
            peripheralRSSIIcon.image = #imageLiteral(resourceName: "rssi_1")
        }
    }
    
    public func peripheralUpdatedAdvertisementData(_ aPeripheral: BlinkyPeripheral) {
        if Date().timeIntervalSince(lastUpdateTimestamp) > 1.0 {
            lastUpdateTimestamp = Date()
            setupView(withPeripheral: aPeripheral)
        }
    }
}
