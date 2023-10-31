// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CalendarSwift",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "CalendarSwift",
            targets: ["CalendarSwift"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CalendarSwift",
            path: "Sources",
            resources: [
                .process("*.xcassets")
            ]
        ),
    ],
    swiftLanguageVersions: [.v4]
)
