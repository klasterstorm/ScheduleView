// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MailScheduleView",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "MailScheduleView",
            targets: ["MailScheduleView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "MailScheduleView"
        ),
        .testTarget(
            name: "MailScheduleViewTests",
            dependencies: ["MailScheduleView"]
        ),
        .testTarget(
            name: "MailScheduleViewSnapshotTests",
            dependencies: [
                "MailScheduleView",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
