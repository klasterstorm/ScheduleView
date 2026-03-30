// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScheduleView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "ScheduleView",
            targets: ["ScheduleView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "ScheduleView"
        ),
        .testTarget(
            name: "ScheduleViewTests",
            dependencies: ["ScheduleView"]
        ),
        .testTarget(
            name: "ScheduleViewSnapshotTests",
            dependencies: [
                "ScheduleView",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
