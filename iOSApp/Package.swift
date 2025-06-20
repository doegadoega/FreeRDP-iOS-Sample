// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "MyRDPApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "YourLibrary", targets: ["MyRDPApp"])
    ],
    dependencies: [
        // R.swift
        .package(url: "https://github.com/mac-cain13/R.swift.Library.git", from: "5.4.0")
    ],
    targets: [
        .target(
            name: "MyRDPApp",
            dependencies: [
                .product(name: "RswiftLibrary", package: "R.swift.Library")
            ]
        ),
        .testTarget(
            name: "YourTargetTests",
            dependencies: ["YourTarget"]
        ),
    ]
)
