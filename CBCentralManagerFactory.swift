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

/// The factory that instantiates the CBCentralManagerType object.
public class CBCentralManagerFactory {
    
    /// Returnes new instance of CBCentralManager.
    /// If MOCK constant is defined for the current target, the
    /// mock instance will be returned.
    /// - Parameter forceMock: A flag to force mocking also on physical device.
    /// - Returns: The CBCentralManager or its mock counterpart.
    public static func instance(forceMock: Bool = false) -> CBCentralManagerType {
        #if targetEnvironment(simulator)
            return CBCentralManagerMock.init()
        #else
            return forceMock ?
                CBCentralManagerMock() :
                CBCentralManagerNative()
        #endif
    }
    
    /// Returnes new instance of CBCentralManager.
    /// If MOCK constant is defined for the current target, the
    /// mock instance will be returned.
    /// - Parameters:
    ///   - delegate: The delegate that will receive central role events.
    ///   - queue: The dispatch queue on which the events will be dispatched.
    ///            If <i>nil</i>, the main queue will be used.
    ///   - forceMock: A flag to force mocking also on physical device.
    /// - Returns: The CBCentralManager or its mock counterpart.
    public static func instance(delegate: CBCentralManagerDelegateType?,
                         queue: DispatchQueue?,
                         forceMock: Bool = false) -> CBCentralManagerType {
        #if targetEnvironment(simulator)
            return CBCentralManagerMock(delegate: delegate, queue: queue)
        #else
            return forceMock ?
                CBCentralManagerMock(delegate: delegate, queue: queue) :
                CBCentralManagerNative(delegate: delegate, queue: queue)
        #endif
    }
    
    /// Returnes new instance of CBCentralManager.
    /// If MOCK constant is defined for the current target, the
    /// mock instance will be returned.
    /// - Parameters:
    ///   - delegate: The delegate that will receive central role events.
    ///   - queue: The dispatch queue on which the events will be dispatched.
    ///            If <i>nil</i>, the main queue will be used.
    ///   - options: An optional dictionary specifying options for the manager.
    ///   - forceMock: A flag to force mocking also on physical device.
    /// - Returns: The CBCentralManager or its mock counterpart.
    public static func instance(delegate: CBCentralManagerDelegateType?,
                         queue: DispatchQueue?,
                         options: [String : Any]?,
                         forceMock: Bool = false) -> CBCentralManagerType {
        #if targetEnvironment(simulator)
            return CBCentralManagerMock(delegate: delegate, queue: queue, options: options)
        #else
            return forceMock ?
                CBCentralManagerMock(delegate: delegate, queue: queue, options: options) :
                CBCentralManagerNative(delegate: delegate, queue: queue, options: options)
        #endif
    }
    
}
