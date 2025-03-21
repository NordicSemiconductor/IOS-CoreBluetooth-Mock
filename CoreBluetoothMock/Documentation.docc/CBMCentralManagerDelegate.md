# ``CoreBluetoothMock/CBMCentralManagerDelegate``

<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->

## Overview

<!--@START_MENU_TOKEN@-->Text<!--@END_MENU_TOKEN@-->

## Topics

### Initialization

- ``centralManagerDidUpdateState(_:)``
- ``centralManager(_:willRestoreState:)``
- ``centralManager(_:didUpdateANCSAuthorizationFor:)``

### Scanning

- ``centralManager(_:didDiscover:advertisementData:rssi:)``

### Connection

Set of callbacks for connection events.

- ``centralManager(_:didConnect:)``
- ``centralManager(_:didFailToConnect:error:)``
- ``centralManager(_:didDisconnectPeripheral:error:)``
- ``centralManager(_:didDisconnectPeripheral:timestamp:isReconnecting:error:)``

### Registering for connection events

- ``centralManager(_:connectionEventDidOccur:for:)``
