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

/// A thread-safe dictionary implementation that uses a concurrent dispatch queue for synchronization.
///
/// - NOTE: This dictionary wrapper does not implement every possible operation and can be expanded as needed
/// for future use
class CBMDictionary<Key: Hashable, Value> {
    private var dictStorage = [Key: Value]()
    
    /// A concurrent queue used for synchronizing access to the dictionary
    private let queue = DispatchQueue(
        label: "CoreBluetoothMock.CBMDictionary.\(UUID().uuidString)",
        qos: .default,
        attributes: .concurrent,
        target: .global()
    )
    
    subscript(key: Key) -> Value? {
        get {
            return queue.sync {
                return dictStorage[key]
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.dictStorage[key] = newValue
            }
        }
    }
    
    /// A collection containing just the values of the dictionary.
    ///
    /// Uses a private queue to ensure thread-safe access when calling `.keys`
    /// on the underlying dictionary.
    var keys: Dictionary<Key, Value>.Keys {
        return queue.sync {
            return dictStorage.keys
        }
    }
    
    /// A collection containing just the values of the dictionary.
    ///
    /// Uses a private queue to ensure thread-safe access when calling `.values`
    /// on the underlying dictionary.
    var values: Dictionary<Key, Value>.Values {
        return queue.sync {
            return dictStorage.values
        }
    }
    
    /// Returns a new dictionary containing the key-value pairs of the dictionary that satisfy the given predicate.
    ///
    /// Uses a private queue to ensure thread-safe access when calling `.filter`
    /// on the underlying dictionary.
    ///
    /// - Parameter isIncluded: A closure that takes a key-value pair as its argument and returns a Boolean value
    /// indicating whether the pair should be included in the returned dictionary.
    /// - Returns: A dictionary of the key-value pairs that isIncluded allows.
    func filter(_ isIncluded: (Dictionary<Key, Value>.Element) throws -> Bool) rethrows -> [Key: Value] {
        return try queue.sync {
            return try dictStorage.filter(isIncluded)
        }
    }
    
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop.
    ///
    /// Uses a private queue to ensure thread-safe access when calling `.forEach`
    /// on the underlying dictionary.
    ///
    /// - Parameter body: A closure that takes an element of the sequence as a parameter.
    func forEach(_ body: (Dictionary<Key, Value>.Element) throws -> Void) rethrows {
        try queue.sync {
            try dictStorage.forEach(body)
        }
    }
    
    /// Removes the given key and its associated value from the dictionary.
    ///
    /// Uses a private queue to ensure thread-safe access when calling `.removeValue`
    /// on the underlying dictionary.
    ///
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns: The value that was removed, or nil if the key was not present in the dictionary.
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        return queue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return nil }
            return self.dictStorage.removeValue(forKey: key)
        }
    }
    
    /// Removes all key-value pairs from the dictionary
    /// 
    /// Uses a private queue to ensure thread-safe access when calling `.removeAll`
    /// on the underlying dictionary.
    func removeAll() {
        queue.sync(flags: .barrier) { [weak self] in
            self?.dictStorage.removeAll()
        }
    }
}
