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

import CoreBluetooth

/// The factory that instantiates the ``CBMCentralManager`` object.
///
/// The factory may be used to automatically instantiate either a native or mock implementation based
/// on the environment. You may also instantiate the ``CBMCentralManagerMock`` or
/// ``CBMCentralManagerNative`` without using this factory.
public class CBMCentralManagerFactory {
    
    /// Returns the implementation of ``CBMCentralManager``, depending on the environment.
    /// On a simulator, or when the `forceMock` flag is enabled, the mock
    /// implementation is returned, otherwise the native one.
    /// - Parameters:
    ///   - forceMock: A flag to force mocking also on physical device.
    /// - Returns: The implementation of ``CBMCentralManager``.
    public static func instance(forceMock: Bool = false) -> CBMCentralManager {
        #if targetEnvironment(simulator)
            return CBMCentralManagerMock()
        #else
            return forceMock ?
                CBMCentralManagerMock() :
                CBMCentralManagerNative()
        #endif
    }
    
    /// Returns the implementation of ``CBMCentralManager``, depending on the environment.
    /// On a simulator, or when the `forceMock` flag is enabled, the mock
    /// implementation is returned, otherwise the native one.
    /// - Parameters:
    ///   - delegate: The delegate that will receive central role events.
    ///   - queue: The dispatch queue on which the events will be dispatched.
    ///            If `nil`, the main queue will be used.
    ///   - forceMock: A flag to force mocking also on a physical device.
    /// - Returns: The implementation of ``CBMCentralManager``.
    public static func instance(delegate: CBMCentralManagerDelegate?,
                                queue: DispatchQueue?,
                                forceMock: Bool = false) -> CBMCentralManager {
        #if targetEnvironment(simulator)
            return CBMCentralManagerMock(delegate: delegate, queue: queue)
        #else
            return forceMock ?
                CBMCentralManagerMock(delegate: delegate, queue: queue) :
                CBMCentralManagerNative(delegate: delegate, queue: queue)
        #endif
    }
    
    /// Returns the implementation of ``CBMCentralManager``, depending on the environment.
    /// On a simulator, or when the `forceMock` flag is enabled, the mock
    /// implementation is returned, otherwise the native one.
    /// - Parameters:
    ///   - delegate: The delegate that will receive central role events.
    ///   - queue: The dispatch queue on which the events will be dispatched.
    ///            If `nil`, the main queue will be used.
    ///   - options: An optional dictionary specifying options for the manager.
    ///   - forceMock: A flag to force mocking also on a physical device.
    /// - Returns: The implementation of ``CBMCentralManager``.
    public static func instance(delegate: CBMCentralManagerDelegate?,
                                queue: DispatchQueue?,
                                options: [String : Any]?,
                                forceMock: Bool = false) -> CBMCentralManager {
        #if targetEnvironment(simulator)
            return CBMCentralManagerMock(delegate: delegate, queue: queue, options: options)
        #else
            return forceMock ?
                CBMCentralManagerMock(delegate: delegate, queue: queue, options: options) :
                CBMCentralManagerNative(delegate: delegate, queue: queue, options: options)
        #endif
    }
}
