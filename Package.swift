// swift-tools-version: 5.9
// Package.swift
import PackageDescription

let package = Package(
    name: "SideNook",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "SideNook",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/SideNook"
        ),
        .testTarget(
            name: "SideNookTests",
            dependencies: ["SideNook"],
            path: "Tests/SideNookTests"
        ),
    ]
)
