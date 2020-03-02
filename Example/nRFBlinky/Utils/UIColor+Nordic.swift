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

extension UIColor {
    
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .light ? light : dark
            }
        } else {
            return light
        }
    }
    
    static let nordicBlue = #colorLiteral(red: 0, green: 0.7181802392, blue: 0.8448022008, alpha: 1)
    static let nordicLake = #colorLiteral(red: 0, green: 0.5483048558, blue: 0.8252354264, alpha: 1)
    
    static let nordicRed = #colorLiteral(red: 0.9567440152, green: 0.2853084803, blue: 0.3770255744, alpha: 1)    
    static let nordicRedDark = #colorLiteral(red: 0.3985097361, green: 0.1188386918, blue: 0.15704134, alpha: 1)
    
    static let nordicFall = #colorLiteral(red: 0.9759542346, green: 0.5849055648, blue: 0.2069504261, alpha: 1)
}
