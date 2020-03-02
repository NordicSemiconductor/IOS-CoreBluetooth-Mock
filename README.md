# CoreBluetooth Mock

The Core Bluetooth framework provides the classes needed for your apps to communicate with Bluetooth-equipped low energy (LE) wireless technology. As the [documentation](https://developer.apple.com/documentation/corebluetooth) states:

> Don’t subclass any of the classes of the Core Bluetooth framework. Overriding these classes isn’t supported and results in undefined behavior.

Besides, Bluetooth isn't supported on the simulator, which makes testing Bluetooth-enabled apps even more difficult.

**Luckily, there is CoreBluetooth Mock library.**

The library wraps `CBCentralManager` and `CBPeripheral` providing both native and mock objects, allowing the
same code to work on physical devices and, with defined mock implementaion, on simulator. Mock may also run mock
on an iPhone, if needed.

## How to start

Import library from CocoaPods:
```
pod 'CoreBluetoothMock'
```

Add `import CoreBluetoothMock` to your classes.

Replace all instances of `CBCentralManager` and `CBPeripheral` to their counterparts from this library: `CBMCentralManager` and `CBMPeripheral`. Do the same with other CoreBluetooth classes and constants.

## nRF BLINKY

nRF Blinky is an example app targeted towards newcomer BLE developers, and also demonstrating the use 
of *CoreBluetooth Mock* library.
This application controls an LED on an [nRF5 DK](https://www.nordicsemi.com/Software-and-Tools/Development-Kits)
and receive notifications whenever the button on the kit is pressed and released.

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
- An iOS device with BLE capabilities, or a simulator (tu run the mock)
- A [Development Kit](https://www.nordicsemi.com/Software-and-Tools/Development-Kits)
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
