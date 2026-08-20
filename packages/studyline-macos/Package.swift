// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyLineMacOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "StudyLineApp",
            targets: ["StudyLineApp"]
        ),
    ],
    dependencies: [
        .package(path: "../studyline-swift")
    ],
    targets: [
        .executableTarget(
            name: "StudyLineApp",
            dependencies: [
                .product(name: "StudyLine", package: "studyline-swift")
            ],
            path: "Sources/StudyLineApp",
            linkerSettings: [
                .unsafeFlags([
                    "-L../../tools/target/release",
                    "-lstudyline_cabi"
                ])
            ]
        ),
    ]
)
