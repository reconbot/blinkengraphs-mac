// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "MacMetrics",
    platforms: [.macOS(.v26)],
    products: [.library(name: "MacMetrics", targets: ["MacMetrics"])],
    dependencies: [
        // Keep in step with project.yml's BlinkengraphsKit version.
        .package(url: "https://github.com/reconbot/blinkengraphs-kit", exact: "2.0.0"),
    ],
    targets: [
        .target(name: "MacMetrics", dependencies: [.product(name: "BlinkengraphsCore", package: "blinkengraphs-kit")]),
        .testTarget(name: "MacMetricsTests", dependencies: ["MacMetrics"]),
    ]
)
