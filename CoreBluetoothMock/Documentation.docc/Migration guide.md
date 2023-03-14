# Migration guide

Migration guide from **CoreBluetooth** to **CoreBluetoothFramework**.

## Overview

The API of the library was designed to similar to the native one to make migration 
from **CoreBluetooth** to **CoreBluetoothMock** easy. Only few changes are required.
Those include initialization of ``CBMCentralManager`` and fixing possible issue with comparing
``CBMPeripheral`` objects.

### Adding dependency

Add dependency to **CoreBluetoothMock** framework using one of the following:
* [Swift Package Manager](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock#swift-package-manager), 
* [CocoaPods](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock#cocoapods)
* [Carthage](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock#carthage).

With this step complete, the migration can be done in one of 2 ways:

#### Using aliases (recommended)

1. Copy [`CoreBluetoothTypeAliases.swift`](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock/blob/main/Example/nRFBlinky/CoreBluetoothTypeAliases.swift)
   file from the *Example app* to your project. 
   This file contains number of type aliases for all `CBM...` types and renames them to `CB...`,
   therfore removing the not need to perform any changes in your code.
2. Optionally, remove: 
   ```swift
   import CoreBluetooth
   ``` 
   in all your files, as the types are now defined locally in the project. This step is not required,
   as locally defined types take precedense over frameworks.

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

### Fixing compilation issues

Whichever approach you have chosen, the project now contain compilation errors.

1. To create an instance of a ``CBMCentralManager`` use
``CBMCentralManagerFactory/instance(delegate:queue:forceMock:)`` instead of creating
the manager using an initializer. The last parameter, `forceMock`, when set to `true`, 
allows to run the mock implementation also on a physical device.

   Before:
   ```swift
   let centralManager = CBCentralManager(delegate: self, queue: .main)
   ```
   After:
   ```swift
   let centralManager = CBCentralManagerFactory.instance(delegate: self, 
                                                         queue: .main,
                                                         forceMock: false)
   ```
2. If you're comparing ``CBMPeripheral`` instances using == operator, replace it with
comparing their identifiers.

   Before:
   ```swift
   peripheral == otherPeripheral 
   ```
   After:
   ```swift
   peripheral.identifier == otherPeripheral.identifier 
   ```

## Migration Example

Check out [Migration example](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock-Example) application for step-by-step guide.
