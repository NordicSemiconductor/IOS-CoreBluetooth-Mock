# ``CoreBluetoothMock/CBMPeripheralSpec``

## Mocking a Real Peripheral

By defining a ``CBMPeripheralSpec`` instance you may create a mock implemntation
of a real Bluetooth LE devices. 

Such device can advertise (broadcast) Bluetooth LE packets, support connection,
handle GATT events, like reading a characterstic value, sending notifications, etc.

A ``CBMCentralManagerMock`` can send scan and send GATT requests to such device just
like the ``CBMCentralManagerNative`` can interact with real devices.

## Topics

### Initialization

- ``simulatePeripheral(identifier:proximity:)``
- ``Builder``

### Simulation Methods

- ``simulateProximityChange(_:)``
- ``simulateValueUpdate(_:for:)``
- ``simulateAdvertisementChange(_:)``
- ``simulateDisconnection(withError:)``
- ``simulateReset()``

### Advanced

- ``simulateConnection()``
- ``simulateCaching()``
- ``simulateMacChange(_:)``
- ``simulateServiceChange(newName:newServices:)``

### Properties

- ``name``
- ``mtu``
- ``advertisement``
- ``identifier``
- ``proximity``
- ``isConnected``
- ``connectionDelegate``
- ``connectionInterval``
- ``isKnown``
- ``services``

### Deprecated

- ``advertisementData``
- ``advertisingInterval``
- ``isAdvertisingWhenConnected``

