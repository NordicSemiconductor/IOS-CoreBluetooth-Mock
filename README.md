# Core Bluetooth Mock

![Version number](https://img.shields.io/cocoapods/v/CoreBluetoothMock) 
[![Platform](https://img.shields.io/cocoapods/p/CoreBluetoothMock.svg?style=flat)](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

The *Core Bluetooth Mock* library was designed to emulate *Core Bluetooth* objects, providing easy way to test 
Bluetooth-enabled apps. As the native Bluetooth API is not supported on a simulator, using this library you can run, test 
and take screenshots of such apps without the need of a physical phone or tablet. You may also start working on the
iOS app when your peripheral is still under development.

### Core Bluetooth?

The [Core Bluetooth](https://developer.apple.com/documentation/corebluetooth) framework provides the classes needed 
for your apps to communicate with Bluetooth-equipped low energy (LE) wireless technology. It requires an iPhone or iPad to 
work making Bluetooth-enabled apps difficult to test. As the documentation states:

> Don’t subclass any of the classes of the Core Bluetooth framework. Overriding these classes isn’t supported and results in 
   undefined behavior.

### Core Bluetooth Mock!

The *Core Bluetooth Mock* library defines number of **CBM...** classes and constants, that wrap or imitate the corresponding
**CB...** counterparts from *Core Bluetooth* framework. For example, `CBMCentralManager` has the same API and 
behavior as `CBCentralManager`, etc. On physical iDevices all calls to `CBMCentralManager` and `CBMPeripheral` are
forwarded to their native equivalents, but on a simulator a mock implementation that you define is used. 

## How to start

The *Core Bluetooth Mock* library is available only in Swift, and compatible with iOS 9.0+, macOS 10.13+, tvOS 9.0+ and watchOS 2.0+,
with some features available only on newer platforms.
For projects running Objective-C we recommend https://github.com/Rightpoint/RZBluetooth library.

### Including the library

The library support [CocoaPods](https://github.com/CocoaPods/CocoaPods), [Carthage](https://github.com/Carthage/Carthage) and 
[Swift Package Manager](https://swift.org/package-manager).

#### CocoaPods

- Create/Update your **Podfile** with the following contents

    ```ruby
    target 'YourAppTargetName' do
        pod 'CoreBluetoothMock'
    end
    ```

- Install dependencies

    ```bash
    pod install
    ```

- Open the newly created `.xcworkspace`

#### Carthage

- Create a new **Cartfile** in your project's root with the following contents

    ```
    github "https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock" ~> x.y // Replace x.y with your required version
    ```
    
- Build with carthage

    ```bash
    carthage update --platform iOS // also supported are tvOS, watchOS and macOS
    ```

- Copy the **CoreBluetoothMock.framework** from *Carthage/Build* to your project and follow [instructions from Carthage](https://github.com/Carthage/Carthage).

#### Swift Package Manager

The library can also be included as SPM package. Simply add it in Xcode: *File -> Swift Packages -> Add package dependency*, 
type *https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock.git* and set required version, branch or commit.

If you have *Swift.package* file, inculde the following dependency:
```swift
dependencies: [
    // [...]
    .package(name: "CoreBluetoothMock", 
             url: "https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock.git", 
             .upToNextMajor(from: "x.y")) // Replace x.y with your required version
]
```
and add it to your target:
```swift
targets: [
    // [...]
    .target(
        name: "<Your target name>",
        dependencies: ["CoreBluetoothMock"]),
]
```

### Usage

With this complete, you need to choose one of the following approaches:

#### Using aliases (recommended)

Copy [CoreBluetoothTypeAliases.swift](Example/nRFBlinky/CoreBluetoothTypeAliases.swift) file to your project. It will create 
number of type aliases for all **CBM...** names and rename them to **CB...**, so you will not need to perform any changes in 
your code, except from removing `import CoreBluetooth` in all your files, as the types are now defined locally.

#### Direct

Replace `import CoreBluetooth` with `import CoreBluetoothMock` in your classes.

Replace all instances of **CB...** with **CBM...**.

### Other required changes

The only difference is how the central manager is instantiated. Instead of:
```swift
let manager = CBCentralManager(delegate: self, queue: ...)
```
you need to use the `CBCentralManagerFactory`:
```swift
let manager = CBCentralManagerFactory.initiate(delegate: self, queue: ...)
```
The last parameter, `forceMock`, when set to *true*, allows to run mock implementation also on a physical device.

### Known issues

- The new `CBMCentralManager` and `CBMPeripheral` are protocols, not classes. That means that, e.g. they cannot 
be used as `Equatable` or `Hashable`. When using in maps, you may need to use the *identifier*. Also, KVO are not yet supported.

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
mock peripheral. This method should be called when the manager is powered off, or before any central manager was initialized.

`CBMCentralManagerMock.tearDownSimulation()` - sets the state of all currently existing central managers to `.unknown` and
clears the list of managers and peripherals bringing the mock manager to initial state.

See [AppDelegate.swift](Example/nRFBlinky/AppDelegate.swift#L48) for reference. In the sample app the mock implementation is
used only in UI Tests, which lauch the app with `mocking-enabled` parameter (see [here](Example/UI%20Tests/UITests.swift#L42)),
but can be easily modified to use it every time it is launched on a simulator or a device.

### Peripheral specs

`CBMPeripheralSpec.Builder` - use the builder to define your mock peripheral. Specify the proximity, whether it is advertising 
together with advertising data and advertising interval, is it connectable (or already connected when your app starts), by defining
its services and their behavior. A list of such peripheral specifications needs to be set by calling the `simulatePeripherals(:)` 
method described above.

`CBMPeripheralSpec.simulateConnection()` - simulates a situation when another app on the iDevice connects to this 
peripheral. It will stop advertising (unless `advertisingWhenConnected` flag was set) and will be available using 
`manager.retrieveConnectedPeripherals(withServices:)`.

`CBMPeripheralSpec.simulateDisconnection(withError:)` - simulates a connection error.

`CBMPeripheralSpec.simulateReset()` - simulates device hard reset. The central will notify delegates 4 seconds (supervision timeout)
after the device has been reset.

`CBMPeripheralSpec.simulateProximityChange(:)` - simulates moving the peripheral close or away from the device.

`CBMPeripheralSpec.simulateValueUpdate(:for:)` - simulates sending a notification or indication from the device. All subscribed
clients will be notified a connection interval later.

See [AppDelegate.swift](Example/nRFBlinky/MockPeripherals.swift#L48) for reference, where 3 mock peripherals are defined: a test blinky
device (like in Nordic SDK), an HRM device (GATT behavior not implemented, as the app does not support it), and a Physical Web Beacon,
a non-connectable device. The 2 latter will not pop up on in the sample app, as it is scanning with Service UUID filter.

### Advanced

`CBMCentralManagerFactory.simulateStateRestoration` - this closure will be used when you initiate a central manager
with `CBMCentralManagerOptionRestoreIdentifierKey` option. The map returned will be passed to
`centralManager(:willRestoreState:)` callback in central manager's delegate.

`CBMCentralManagerFactory.simulateFeaturesSupport` - this closure will be used to emulate Bluetooth features supported
by the manager. It is availalbe on iOS 13+, tvOS 13+ or watchOS 6+.

## Sample application: nRF BLINKY

nRF Blinky is an example app targeted towards newcomer BLE developers, and also demonstrating the use 
of *Core Bluetooth Mock* library. This application controls an LED on an
[nRF5DK](https://www.nordicsemi.com/Software-and-Tools/Development-Kits)
and receive notifications whenever the button on the kit is pressed and released.

The mock implementation is used in UI tests. See [AppDelegate.swift](Example/nRFBlinky/AppDelegate.swift) 
and [UITests.swift](Example/UI%20Tests/UITests.swift) classes.

## Nordic LED and Button Service

A simplified proprietary service by Nordic Semiconductor, containing two characteristics one to control LED3 and Button1:
- Service UUID: **`00001523-1212-EFDE-1523-785FEABCD123`**
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
