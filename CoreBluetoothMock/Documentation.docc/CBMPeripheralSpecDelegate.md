# ``CoreBluetoothMock/CBMPeripheralSpecDelegate``

## Topics

### Handling Connection Events

- ``peripheralDidReceiveConnectionRequest(_:)-6eqgz``
- ``peripheral(_:didDisconnect:)-37v65``
- ``reset()-7utrg``

### Handling Service Discovery

The default implementation will successfully return all requested attributes. This can be modified to return an error, if needed.

- ``peripheral(_:didReceiveServiceDiscoveryRequest:)-pq5f``
- ``peripheral(_:didReceiveIncludedServiceDiscoveryRequest:for:)-4mqk2``
- ``peripheral(_:didReceiveCharacteristicsDiscoveryRequest:for:)-2doal``
- ``peripheral(_:didReceiveDescriptorsDiscoveryRequestFor:)-6rk13``

### Handling Requests

- ``peripheral(_:didReceiveReadRequestFor:)-9ybod``
- ``peripheral(_:didReceiveReadRequestFor:)-7sk6x``
- ``peripheral(_:didReceiveWriteCommandFor:data:)-58pcn``
- ``peripheral(_:didReceiveWriteRequestFor:data:)-yspa``
- ``peripheral(_:didReceiveWriteRequestFor:data:)-81sdk``

### Handling Notifications

- ``peripheral(_:didReceiveSetNotifyRequest:for:)-9r03q``
- ``peripheral(_:didUpdateNotificationStateFor:error:)-4aash``

