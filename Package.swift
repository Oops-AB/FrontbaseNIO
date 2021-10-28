// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "FrontbaseNIO",
    products: [
        .library (name: "FrontbaseNIO", targets: ["FrontbaseNIO"]),
    ],
    dependencies: [
        // 🚀 Event driven non-blocking framework.
        .package (url: "https://github.com/apple/swift-nio.git", from: "2.28.0"),

        // 📜 A Logging API for Swift.
        .package (url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .systemLibrary(
            name: "FBCAccess",
            pkgConfig: "FBCAccess"
        ),
        .target (name: "FrontbaseNIO", dependencies: ["CFrontbaseSupport", "NIO", "Logging"]),
        .target (
            name: "CFrontbaseSupport",
            dependencies: [ "FBCAccess" ],
            linkerSettings: [
                .linkedFramework ("IOKit", .when (platforms: [ .macOS, .iOS, .watchOS, .tvOS ])),
                .linkedFramework ("CoreFoundation", .when (platforms: [ .macOS, .iOS, .watchOS, .tvOS ])),
                .linkedLibrary ("z", .when (platforms: [ .macOS, .iOS, .watchOS, .tvOS ])),
            ]),
        .target (name: "MemoryTools", dependencies: []),
        .testTarget (name: "FrontbaseNIOTests", dependencies: ["FrontbaseNIO", "FBCAccess", "MemoryTools"]),
    ]
)
