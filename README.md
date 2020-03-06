# Core Bluetooth Mock

The *Core Bluetooth Mock* library allows mocking *Core Bluetooth* objects, providing easy way to test Bluetooth-enabled apps
on a simulator, or run them without a physical Bluetooth LE peripheral.

### Core Bluetooth?

The [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth) framework provides the classes needed 
for your apps to communicate with Bluetooth-equipped low energy (LE) wireless technology. As the documentation states:

> Don’t subclass any of the classes of the Core Bluetooth framework. Overriding these classes isn’t supported and results in 
   undefined behavior.

Bluetooth isn't supported on the simulator, which makes testing Bluetooth-enabled apps even more difficult.

### Core Bluetooth Mock!

The *Core Bluetooth Mock* library defines number of **CBM...** classes and constants, that wrap or imitate the corresponding
**CB...** classes and constants from *Core Bluetooth* framework. For example, `CBMCentralManager` has the same API and 
behavior as `CBCentralManager`, etc.

## How to start

The *Core Bluetooth Mock* library is available only in Swift, and compatible with iOS 8.0+. For projects running Objective-C 
we recommend https://github.com/Rightpoint/RZBluetooth library.

Import library from CocoaPods:
```
pod 'CoreBluetoothMock'
```

Then, you need to choose one of the following approaches:

### Using aliases

This solution is much easier to implement, and therefor recommended.

Copy [CoreBluetoothTypeAliases.swift](.../Example/nRFBlinky/CoreBluetothTypeAliases.swift) file to your project. It will create 
number of type aliases for all **CBM...** names and rename them to **CB...**, so you will not need to perform any changes in 
your files, except from removing `import CoreBluetooth` in all your files, as the types are now defined locally.

### Direct

Replace `import CoreBluetooth` with `import CoreBluetoothMock` in your classes.

Replace all instances of **CB...** with **CBM...**.

### Other required changes

The only difference you will notice is how the central manager is instantiated. Instead of:
```swift
let manager = CBCentralManager(delegate: self, queue: ...)
```
you need to use the `CBCentralManagerFactory`:
```swift
let manager = CBCentralManagerFactory.initiate(delegate: self, queue: ...)
```
With these changes your app should work exactly the same as without any changes. On physical iDevices all calls in 
`CBMCentralManager` and `CBMPeripheral` are forwarded to their native counterparts.

## Defining mock peripherals

When the app using *Core Bluetooth Mock* library is started on a simulator, or the `forceMock` parameter is set to *true* during 
instantiating a central manager instance, a mock version of central manager will be created. Use the following methods and 
properties to simulate central manager behavior:

### Basic

`CBMCentralManagerMock.simulateInitialState(_ state: CBMManagerState)` -  this method should be called before
any central manager instance was created. It defines the intial state of the mock central manager. By default, the manager is powered off.

`CBMCentralManager.simulatePowerOn()` - turns on the mock central manager.

`CBMCentralManager.simulatePowerOff()` - turns off the mock central manager. All scans and connections will be terminated.

`CBMCentralManagerMock.simulatePeripherals(_ peripherals: [CBMPeripheralSpec])` - defines list of 
mock peripheral. This method should be called once, before any central manager was initialized.

### Peripheral specs

`CBMPeripheralSpec.Builder` - use the builder to define your mock peripheral. Specify the proximity, whether it is advertising 
together with advertising data and advertising interval, is it connectable (or already connected when your app starts), by defining
its services and their behavior. List of such peripheral specifications need to be set using the above `simulatePeripherals(:)` 
method.

`CBMPeripheralSpec.simulateConnection()` - simulates a situation when another app on the iDevice connects to this 
peripheral. It will stop advertising (unless `advertisingWhenConnected` flag was set) and will be available using 
`manager.retrieveConnectedPeripherals(withServices:)`.

`CBMPeripheralSpec.simulateDisconnection(withError:)` - simulates a connection error.

`CBMPeripheralSpec.simulateReset()` - simulates device hard reset. The central will notify delegates 4 seconds (supervision timeout)
after the device has been reset.

`CBMPeripheralSpec.simulateProximityChange(:)` - simulates moving the peripheral close or away from the device.

`CBMPeripheralSpec.simulateValueUpdate(:for:)` - simulates sending a notification or indication from the device. All subscribed
clients will be notified a connection interval later.

### Advanced

`CBMCentralManagerFactory.simulateStateRestoration` - this closure will be used when you initiate a central manager
with `CBMCentralManagerOptionRestoreIdentifierKey` option. The map returned will be passed to
`centralManager(:willRestoreState:)` callback in central manager's delegate.

`CBMCentralManagerFactory.simulateFeaturesSupport` - this closure will be used to emulate Bluetooth features supported
by the manager. It is availalbe on iOS 13+.

## Sample application: nRF BLINKY

nRF Blinky is an example app targeted towards newcomer BLE developers, and also demonstrating the use 
of *Core Bluetooth Mock* library.
This application controls an LED on an [nRF5 DK](https://www.nordicsemi.com/Software-and-Tools/Development-Kits)
and receive notifications whenever the button on the kit is pressed and released.

The mock implementation is used in UI tests. See `AppDelegate.swift` and `UITests.swift` classes.

## Nordic LED and Button Service
###### Service UUID: `00001523-1212-EFDE-1523-785FEABCD123`
A simplified proprietary service by Nordic Semiconductor, containing two characteristics one to control LED3 and Button1:
- First characteristic controls the LED state (On/Off).
  - UUID: **`00001525-1212-EFDE-1523-785FEABCD123`**
  - Value: **`1`** => LED On
  - Value: **`0`** => LED Off
- Second characteristic notifies central of the button state on change (Pressed/Released).
  - UUID: **`00001524-1212-EFDE-1523-785FEABCD123`**
  - Value: **`1`** => Button Pressed
  - Value: **`0`** => Button Released
  
  For full specification, check out 
  [documentation](https://infocenter.nordicsemi.com/topic/sdk_nrf5_v16.0.0/ble_sdk_app_blinky.html?cp=7_1_4_2_2_3).

## Requirements:
- An iOS device with BLE capabilities, or a simulator (to run the mock)
- A [Development Kit](https://www.nordicsemi.com/Software-and-Tools/Development-Kits) (unless testing mock)
- The Blinky example firmware to flash on the Development Kit. For your conveninence, we have bundled two firmwares in this project under the Firmwares directory.
- To get the latest firmwares and check the source code, you may go directly to our [Developers website](http://developer.nordicsemi.com/nRF5_SDK/) and download the SDK version you need, then you can find the source code and hex files to the blinky demo in the directory `/examples/ble_peripheral/ble_app_blinky/`
-  More information about the nRFBlinky example firmware can be found in the [documentation](https://infocenter.nordicsemi.com/topic/sdk_nrf5_v16.0.0/ble_sdk_app_blinky.html?cp=7_1_4_2_2_3).

## Installation and usage:
- Prepare your Development kit.
  - Plug in the Development Kit to your computer via USB.
  - Power On the Development Kit.
  - The Development Kit will now appear as a Mass storage device.
  - Drag (or copy/paste) the appropriate HEX file onto that new device.
  - The Development Kit LEDs will flash and it will disconnect and reconnect.
  - The Development Kit is now ready and flashed with the nRFBlinky example firmware.

- Start Xcode and run build the project against your target iOS Device (**Note:** BLE is not available in the iOS simulator, so the iOS device is a requirement to test with real hardware).
  - Launch the **nRF Blinky** app on your iOS device.
  - The app will start scanning for nearby peripherals.
  - Select the **Nordic_Blinky** peripheral that appears on screen (**Note:** if the peripheral does not show up, ensure that it's powered on and functional).
  - Your iOS device will now connect to the peripheral and state is displayed on the screen.
  - Changing the value of the Toggle switch will turn LED 3 on or off.
  - Pressing Button 1 on the Development Kit will show the button state as Pressed on the app.
  - Releasing Button 1 will show the state as Released on the App.
