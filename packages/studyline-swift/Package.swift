// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyLineSwift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StudyLine",
            targets: ["StudyLine"]
        ),
    ],
    targets: [
        .target(
            name: "CStudyLine",
            dependencies: [],
            path: "Sources/CStudyLine",
            publicHeadersPath: "include"
        ),
        .target(
            name: "StudyLine",
            dependencies: ["CStudyLine"],
            path: "Sources/StudyLine",
            linkerSettings: [
                .unsafeFlags([
                    "-L../../tools/target/release",
                    "-lstudyline_cabi"
                ])
            ]
        ),
        .testTarget(
            name: "StudyLineTests",
            dependencies: ["StudyLine"],
            path: "Tests/StudyLineTests"
        ),
    ]
)
