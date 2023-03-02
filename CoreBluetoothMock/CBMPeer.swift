import Foundation

/// An object that represents a remote device.
///
/// The `CBMPeer` class is an abstract base class that defines common behavior for objects representing remote devices.
/// You typically don’t create instances of either `CBMPeer` or its concrete subclasses. Instead, the system creates them
/// for you during the process of peer discovery.
///
/// Your app takes the role of either a central (by creating an instance of ``CBMCentralManager``) or a peripheral
/// (by creating an instance of `CBPeripheralManager`), and interacts through the manager with remote devices in
/// the opposite role. During the process of peer discovery, where a central device scans for peripherals advertising services,
/// the system creates objects from the concrete subclasses of `CBMPeer` to represent discovered remote devices.
/// The concrete subclasses of `CBPeer` are ``CBMPeripheral`` and `CBCentral`.
open class CBMPeer: NSObject {
    
    /// The UUID associated with the peer.
    var identifier: UUID {
        fatalError()
    }
}
