// swift-tools-version:5.1
//
// The `swift-tools-version` declares the minimum version of Swift required to
// build this package. Do not remove it.

import PackageDescription

let package = Package(
  name: "CoreBluetoothMock",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v8),
    .watchOS(.v4),
    .tvOS(.v11)
  ],
  products: [
    .library(name: "CoreBluetoothMock", targets: ["CoreBluetoothMock"])
  ],
  targets: [
    .target(
      name: "CoreBluetoothMock",
      path: "CoreBluetoothMock/Classes/"
    )
  ],
  swiftLanguageVersions: [.v5]
)
