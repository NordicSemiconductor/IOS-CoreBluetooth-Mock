// swift-tools-version:5.6
//
// The `swift-tools-version` declares the minimum version of Swift required to
// build this package. Do not remove it.

import PackageDescription

let package = Package(
  name: "CoreBluetoothMock",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v11),
    .watchOS(.v4),
    .tvOS(.v11)
  ],
  products: [
    .library(name: "CoreBluetoothMock", targets: ["CoreBluetoothMock"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "CoreBluetoothMock",
      path: "CoreBluetoothMock/"
    )
  ],  
  swiftLanguageVersions: [.v5]
)
