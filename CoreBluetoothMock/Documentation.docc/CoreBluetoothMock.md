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

## Topics

### How to migrate a project to CoreBluetooth Mock framework

- <doc:Migration-guide>

### How to create mock peripherals

- <doc:Mocking-peripherals>

### How to simulate test events

- <doc:Simulation>

### Known issues

- <doc:Known-issues>

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
- ``CBMManagerAuthorization``

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
- ``CBML2CAPPSM``
- ``CBML2CAPChannel``

### Peripheral Connection Options

Keys used to pass options when connecting to a peripheral.

- ``CBMConnectPeripheralOptionNotifyOnConnectionKey``
- ``CBMConnectPeripheralOptionNotifyOnDisconnectionKey``
- ``CBMConnectPeripheralOptionNotifyOnNotificationKey``
- ``CBMConnectPeripheralOptionEnableTransportBridgingKey``
- ``CBMConnectPeripheralOptionRequiresANCS``
- ``CBMConnectPeripheralOptionStartDelayKey``

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

Keys used to pass options when scanning for peripherals.

- ``CBMCentralManagerScanOptionAllowDuplicatesKey``
- ``CBMCentralManagerScanOptionSolicitedServiceUUIDsKey``

### Advertisement Data Retrieval Keys

Keys used to specify items in a dictionary of peripheral advertisement data.

- ``CBMAdvertisementDataLocalNameKey``
- ``CBMAdvertisementDataManufacturerDataKey``
- ``CBMAdvertisementDataServiceDataKey``
- ``CBMAdvertisementDataServiceUUIDsKey``
- ``CBMAdvertisementDataOverflowServiceUUIDsKey``
- ``CBMAdvertisementDataTxPowerLevelKey``
- ``CBMAdvertisementDataIsConnectable``
- ``CBMAdvertisementDataSolicitedServiceUUIDsKey``

### Other

- ``CBMUUID``
- ``CBMError``
- ``CBMATTError``
