// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KOSUniversalArduino",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "KOSUniversalArduino", targets: ["KOSUniversalArduino"])],
    targets: [
        .target(name: "KOSUniversalArduino"),
        .testTarget(name: "KOSUniversalArduinoTests", dependencies: ["KOSUniversalArduino"])
    ]
)
