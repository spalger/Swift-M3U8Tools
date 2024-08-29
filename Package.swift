// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "M3U8Tools",
  platforms: [
    .iOS(.v13), .macOS(.v10_15), .macCatalyst(.v13), .tvOS(.v13), .visionOS(.v1), .watchOS(.v6),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "M3U8Tools", targets: ["M3U8Tools"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.10.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(name: "M3U8Tools"),
    .testTarget(
      name: "M3U8ToolsTests",
      dependencies: [
        "M3U8Tools",
        .product(name: "Testing", package: "swift-testing"),
      ]
    ),
  ]
)
