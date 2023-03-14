# Known issues

Known issues when using **CoreBluetoothMock** framework instead of native **CoreBluetooth**.

## Overview

By design, the library should behave exatly the same as the native implementation and no
code changes above those mentioned in <doc:Migration-guide> should be necessary.

However, to make mocking possible, some tradeoffs were made.

### Differences vs native API

1. As ``CBMPeripheral`` is a *protocol*, the KVO features are not available. 
   See [#10](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock/issues/10).

### Not implemented

1. As of now, the `CBPeripheralManager` is not supported. 
   See [#40](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock/issues/40).
2. Bluetooth authorization popups are not implemented.
   See [#64](https://github.com/NordicSemiconductor/IOS-CoreBluetooth-Mock/issues/64).
