// swift-tools-version:5.4
//
// The `swift-tools-version` declares the minimum version of Swift required to
// build this package. Do not remove it.

import PackageDescription

let package = Package(
  name: "CoreBluetoothMock",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v9),
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
