# ``CoreBluetoothMock``

Test **CoreBluetooth** features in your app using mocks.

## Overview

The **CoreBluetoothMock** library provides an intuitive API for mocking physical 
Bluetooth LE devices using an implementation in Swift. This allows:
* Testing Bluetooth LE connectivity on a simulator,
* Simulating a Bluetooth LE device during the development phase,
* Reliable method for automating tests and taking screenshots.

> Note: Current version supports testing only central manager features. 
        The peripheral manager functionality is planned.

## Migration

To make migration from **CoreBluetooth** to **CoreBluetoothMock** easy the API of the 
library was designed to similar to the native one. Only a few changes are required, 
most of them involve changing or removing the `import CoreBluetooth` statement, not the 
application code.

The migration can be done in one of 2 ways:

#### Using aliases (recommended)

1. Copy `CoreBluetoothTypeAliases.swift` file from the *Example app* to your project. 
   This file contains number of type aliases for all `CBM...` types and renames them to `CB...`,
   therfore removing the not need to perform any changes in your code. 
2. Remove: 
   ```swift
   import CoreBluetooth
   ``` 
   in all your files, as the types are now defined locally in the project.

#### Direct

1. In all files using **CoreBluetooth** replace 
   ```swift
   import CoreBluetooth
   ``` 
   with 
   ```swift 
   import CoreBluetoothMock
   ```
2. Replace all instances of `CB...` with `CBM...`.

### Initialization

Due to the fact, that the library provides two different implementations of ``CBMCentralManager``
there is a difference, comparing to the native API, how the manager is initialized. Instead of:
```swift
let manager = CBCentralManager(delegate: self, queue: ..., options: ...)
```
you need to use the ``CBMCentralManagerFactory``:
```swift
let manager = CBMCentralManagerFactory.initiate(delegate: self, queue: ..., options: ..., forceMock: ...)
```
The last parameter, `forceMock`, when set to `true`, allows to run the mock implementation
also on a physical device.

## Mocking Bluetooth LE Devices

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

## Simulation

``CBMPeripheralSpec/simulateConnection()`` - simulates a situation when another app on the iDevice
connected to this peripheral. The device will stop advertising (unless `advertisingWhenConnected` 
flag was set) and will be available using
``CBMCentralManager/retrieveConnectedPeripherals(withServices:)``.

``CBMPeripheralSpec/simulateDisconnection(withError:)`` - simulates a connection error.

``CBMPeripheralSpec/simulateReset()`` - simulates device hard reset. The central will notify 
delegates 4 seconds (supervision timeout) after the device has been reset.

``CBMPeripheralSpec/simulateProximityChange(_:)`` - simulates moving the peripheral close or away 
from the device.

``CBMPeripheralSpec/simulateValueUpdate(_:for:)`` - simulates sending a notification or indication 
from the device. All subscribed clients will be notified a connection interval later.

``CBMPeripheralSpec/simulateAdvertisementChange(_:)`` - simulates change of the advertisemet data
of the peripheral. The peripheral will stop advertising with previous data and start with the new set.

``CBMPeripheralSpec/simulateCaching()`` - simulates caching the device by the iDevice. 
Caching pairs the device's MAC with a random identifier (UUID). A device is also cached whenever 
it is scanned. Caching makes the device available to be retrieved using
``CBMCentralManager/retrievePeripherals(withIdentifiers:)``.

``CBMPeripheralSpec/simulateMacChange(_:)`` - simulates the device changing its MAC address. 
The iDevice will not contain any cached information about the device, as with the new MAC it is
considered to be a new device.


### Bluetooth State Changes

``CBMCentralManagerMock/simulatePeripherals(_:)`` - creates a simulation with given list of mock
peripheral. This method should be called when the manager is powered off, or before any 
central manager was initialized.

``CBMCentralManagerMock/simulateInitialState(_:)`` - this method should be called before any central
manager instance was created. It defines the initial state of the mock central manager. 
By default, the manager is powered off.

``CBMCentralManagerMock/simulatePowerOn()`` - turns on the mock central manager.

``CBMCentralManagerMock/simulatePowerOff()`` - turns off the mock central manager. 
All scans and connections will be terminated.

``CBMCentralManagerMock/tearDownSimulation()`` - sets the state of all currently existing central
managers to ``CBMManagerState/unknown`` and clears the list of managers and peripherals bringing 
the mock manager to initial state.

``CBMCentralManagerMock/simulateStateRestoration`` - this closure will be used when you initiate a
central manager with ``CBMCentralManagerOptionRestoreIdentifierKey`` option. The map returned will be
passed to ``CBMCentralManagerDelegate/centralManager(_:willRestoreState:)-9qavl`` callback in 
central manager's delegate.

``CBMCentralManagerMock/simulateFeaturesSupport`` - this closure will be used to emulate Bluetooth
features supported by the manager. It is available on iOS 13+, tvOS 13+ or watchOS 6+.

``CBMCentralManagerMock/simulateAuthorization(_:)`` - simulates the current authorization state 
of a Core Bluetooth manager. When any value other than `.allowedAlways` is returned, the
``CBMCentralManager`` will change state to ``CBMManagerState/unauthorized``.

## Known limitations

As ``CBMPeripheral`` is a *protocol*, the KVO features are not available. See [#10](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock/issues/10).

## Topics

### Mocking Bluetooth LE Devices

The following objects can be used to create mock implementation of Bluetooth LE
devices. Such mock peripherals will be available using ``CBMCentralManagerMock``.

- ``CBMPeripheralSpec``
- ``CBMPeripheralSpecDelegate``
- ``CBMProximity``
- ``CBMAdvertisementConfig``

### Central Manager

- ``CBMCentralManagerFactory``
- ``CBMCentralManager``
- ``CBMCentralManagerDelegate``
- ``CBMCentralManagerDelegateProxy``
- ``CBMCentralManagerMock``
- ``CBMCentralManagerNative``
- ``CBMManagerState``

### Central Manager Initialization Options

Keys used to pass options when initializing a central manager.

- ``CBMCentralManagerOptionRestoreIdentifierKey``
- ``CBMCentralManagerOptionShowPowerAlertKey``

### Central Manager State Restoration Options

Keys used to pass state restoration options to the central manager initializer.

- ``CBMCentralManagerRestoredStatePeripheralsKey``
- ``CBMCentralManagerRestoredStateScanServicesKey``
- ``CBMCentralManagerRestoredStateScanOptionsKey``

### Peripheral

- ``CBMPeer``
- ``CBMPeripheral``
- ``CBMPeripheralDelegate``
- ``CBMPeripheralDelegateProxy``
- ``CBMPeripheralDelegateProxyWithL2CAPChannel``
- ``CBMPeripheralMock``
- ``CBMPeripheralNative``
- ``CBMPeripheralPreview``
- ``CBMPeripheralState``

### Attributes

- ``CBMAttribute``
- ``CBMService``
- ``CBMServiceMock``
- ``CBMCharacteristic``
- ``CBMCharacteristicWriteType``
- ``CBMCharacteristicProperties``
- ``CBMCharacteristicMock``
- ``CBMDescriptor``
- ``CBMDescriptorMock``
- ``CBMClientCharacteristicConfigurationDescriptorMock``
- ``CBMCCCDescriptorMock``

### Scanning options

- ``CBMCentralManagerScanOptionAllowDuplicatesKey``
- ``CBMCentralManagerScanOptionSolicitedServiceUUIDsKey``

### Advertisement Data Keys

- ``CBMAdvertisementDataIsConnectable``
- ``CBMAdvertisementDataLocalNameKey``
- ``CBMAdvertisementDataManufacturerDataKey``
- ``CBMAdvertisementDataOverflowServiceUUIDsKey``
- ``CBMAdvertisementDataServiceDataKey``
- ``CBMAdvertisementDataServiceUUIDsKey``
- ``CBMAdvertisementDataSolicitedServiceUUIDsKey``
- ``CBMAdvertisementDataTxPowerLevelKey``
