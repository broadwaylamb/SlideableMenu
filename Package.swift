// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SlideableMenu",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SlideableMenu", targets: ["SlideableMenu"]),
    ],
    targets: [
        .target(name: "SlideableMenu"),
    ]
)
