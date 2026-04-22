// swift-tools-version: 6.0
// Package.swift
import PackageDescription

let package = Package(
    name: "SideNook",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "SideNook",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/SideNook",
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .testTarget(
            name: "SideNookTests",
            dependencies: ["SideNook"],
            path: "Tests/SideNookTests",
            swiftSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                ]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework", "Testing",
                ]),
            ]
        ),
    ]
)
