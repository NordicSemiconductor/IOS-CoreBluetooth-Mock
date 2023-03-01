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

Such mocked peripherals must be added to the simulation using
``CBMCentralManagerMock/simulatePeripherals(_:)``. 

```swift
CBMCentralManagerMock.simulatePeripherals[blinky]
```

From that moment simulated advertising starts and the device can be scanned or retrieved 
just like physical devices.

### Advertising

A mock peripheral may advertise with static data with a fixed advertising interval, using a
one-time advertisements or change advertising during the simulation.

The initial advertising configuration is set up using
``CBMPeripheralSpec/Builder/advertising(advertisementData:withInterval:delay:alsoWhenConnected:)``, 
which can be called multiple times, if required.

The advertisement data of each mock peripheral can be changed during the simulation using 
``CBMPeripheralSpec/simulateAdvertisementChange(_:)``.

### Connection

The
``CBMPeripheralSpec/Builder/connectable(name:services:delegate:connectionInterval:mtu:)``
method allows to specify a ``CBMPeripheralSpecDelegate``. This object defines the behavior of the
mock peripheral, how will it respond to Bluetooth LE requests, a hard reset, etc. The implementation
should mimic the behavoir of the real device as much as possible to make the tests reliable.

### Bluetooth State Changes

Apart from simulating the behavior of mocked peripherals this library also provides an API
to simulate changes in the phone environment. Methods like
``CBMCentralManagerMock/simulatePowerOn()`` or ``CBMCentralManagerMock/simulatePowerOff()`` can
simulate turning OFF Bluetooth on the phone. 
``CBMCentralManagerMock/simulateFeaturesSupport`` can simulate features supported by the device.
``CBMCentralManagerMock/simulateAuthorization(_:)`` may be used to test the app when the used
does not authorize Bluetooth.

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
