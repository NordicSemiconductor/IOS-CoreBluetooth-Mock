# ``CoreBluetoothMock/CBMPeripheral``

## Topics

### Identifying a Peripheral

- ``identifier``
- ``name``
- ``delegate``

### Discovering Services

- ``discoverServices(_:)``
- ``discoverIncludedServices(_:for:)``
- ``services``

### Discovering Characteristics and Descriptors

- ``discoverCharacteristics(_:for:)``
- ``discoverDescriptors(for:)``

### Reading Characteristic and Descriptor Values

- ``readValue(for:)-1hqxp``
- ``readValue(for:)-3xyb1``

### Writing Characteristic and Descriptor Values

- ``writeValue(_:for:type:)``
- ``writeValue(_:for:)``
- ``maximumWriteValueLength(for:)``
- ``CBMCharacteristicWriteType``

### Setting Notifications for a Characteristic’s Value

- ``setNotifyValue(_:for:)``

### Monitoring a Peripheral’s Connection State

- ``state``
- ``CBMPeripheralState``
- ``canSendWriteWithoutResponse``

### Accessing a Peripheral’s Signal Strength

- ``readRSSI()``

### Working with L2CAP Channels

L2CAP features are not supported by this library.

- ``openL2CAPChannel(_:)``
- ``CBML2CAPPSM``
- ``CBML2CAPChannel``

### Working with Apple Notification Center Service (ANCS)

- ``ancsAuthorized``
