# ``CoreBluetoothMock/CBMCentralManager``

## Initialization

The CoreBluetoothMock library provides two implementations of `CBMCentralManager`:
- ``CBMCentralManagerNative``
- ``CBMCentralManagerMock``

Because of this, instance of the manager has to be created using a
``CBMCentralManagerFactory``.
```swift
let manager = CBMCentralManagerFactory.initiate(delegate: self, queue: ...)
```

## Topics

### Initialization

Do not create instances of the manager using this method. 
Instead, use ``CBMCentralManagerFactory``.

- ``init(_:)``

### Establishing or Canceling Connections with Peripherals

- ``connect(_:options:)``
- ``cancelPeripheralConnection(_:)``

### Retrieving Lists of Peripherals

- ``retrieveConnectedPeripherals(withServices:)``
- ``retrievePeripherals(withIdentifiers:)``

### Scanning or Stopping Scans of Peripherals

- ``scanForPeripherals(withServices:options:)``
- ``stopScan()``
- ``isScanning``

### Inspecting Feature Support

- ``supports(_:)``
- ``Feature``

### Monitoring Properties

- ``delegate``
- ``state``
- ``authorization-swift.type.property``

### Receiving Connection Events

- ``registerForConnectionEvents(options:)``
- ``CBMConnectionEvent``
- ``CBMConnectionEventMatchingOption``

### Deprecated

- ``authorization-swift.property``
