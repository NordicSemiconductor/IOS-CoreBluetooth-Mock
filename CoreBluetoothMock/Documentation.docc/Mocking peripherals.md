# Mocking Bluetooth LE Devices

How to create mock peripherals to be used in tests.

## Overview

The ``CBMCentralManagerFactory`` provides two implementatons of ``CBMCentralManager``:
* ``CBMCentralManagerNative``
* ``CBMCentralManagerMock``

The native implementation proxies all requests to the **CoreBluetooth** framework.

When the code runs on a simulator (or the `forceMock` parameter was set) a mock manager 
is created. Instead of physical devices, this manager interacts with mock implementations, 
defined as ``CBMPeripheralSpec``. Such peripheral specification should emulate the actual 
behavior of a real device as close as possible. 

### Defining a Mock Peripheral

To create a mock peripheral use
``CBMPeripheralSpec/simulatePeripheral(identifier:proximity:)``. This method returns a
``CBMPeripheralSpec/Builder`` instance which can set up advertisements and connection behavior.
Any number of such specifications can be defined.

Sample code:
```swift
let blinky = CBMPeripheralSpec
    .simulatePeripheral(proximity: .near)
    .advertising(
        advertisementData: [
            CBMAdvertisementDataLocalNameKey    : "nRF Blinky",
            CBMAdvertisementDataServiceUUIDsKey : [CBMUUID.nordicBlinkyService],
            CBMAdvertisementDataIsConnectable   : true as NSNumber
        ],
        withInterval: 0.250)
    .connectable(
        name: "nRF Blinky",
        services: [.blinkyService],
        delegate: BlinkyCBMPeripheralSpecDelegate(),
        connectionInterval: 0.045,
        mtu: 23)
    .build()
```

Such mock peripherals must be added to the simulation using
``CBMCentralManagerMock/simulatePeripherals(_:)``. 

```swift
CBMCentralManagerMock.simulatePeripherals([blinky])
```

From that moment simulated advertising starts and the device can be scanned or retrieved 
just like physical devices.

### Advertising

A mock peripheral may advertise with:
* static data with a fixed advertising interval, 
* *one-time* advertisements (`interval` set to 0),

Both types of advertisements can be delayed using the `delay` parameter.

The initial advertising configuration is set up using
``CBMPeripheralSpec/Builder/advertising(advertisementData:withInterval:delay:alsoWhenConnected:)``, 
which can be called multiple times, if required.

The advertisement data can be changed during the simulation using
``CBMPeripheralSpec/simulateAdvertisementChange(_:)``.

### Connection

The
``CBMPeripheralSpec/Builder/connectable(name:services:delegate:connectionInterval:mtu:)`` or 
``CBMPeripheralSpec/Builder/connected(name:services:delegate:connectionInterval:mtu:)``
methods allows to specify a ``CBMPeripheralSpecDelegate``. This object defines the behavior of the
mock peripheral, how will it respond to Bluetooth LE requests, a hard reset, etc. The implementation
should mimic the behavoir of the real device as much as possible to make the tests reliable.

To test how the app handles connection interruptions, the mock connection can be terminated using
``CBMPeripheralSpec/simulateReset()``, ``CBMPeripheralSpec/simulateDisconnection(withError:)`` or
``CBMPeripheralSpec/simulateProximityChange(_:)`` with parameter ``CBMProximity/outOfRange``.
