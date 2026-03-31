// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "SagaLeafRenderer",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "SagaLeafRenderer",
      targets: ["SagaLeafRenderer"]),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga.git", from: "3.1.0"),
    .package(url: "https://github.com/vapor/leaf-kit", from: "1.13.0"),
  ],
  targets: [
    .target(
      name: "SagaLeafRenderer",
      dependencies: [
        "Saga",
        .product(name: "LeafKit", package: "leaf-kit")
      ]
    ),
  ]
)
