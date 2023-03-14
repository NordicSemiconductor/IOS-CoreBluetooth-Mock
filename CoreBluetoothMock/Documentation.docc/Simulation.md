# Simulation

Set of methods for simulating various Bluetooth LE events. 

## Overview

**CoreBluetoothMock** framework allows to simulate various events that can happen in 
real life scenario. Those include turning OFF Bluetooth, resetting the device, sending 
notifications, moving devices out of range, etc.

### 

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

