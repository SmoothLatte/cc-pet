// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cc-pet",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "CCPet",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios"),
            ],
            path: "CCPet",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CCPetTests",
            dependencies: ["CCPet"],
            path: "CCPetTests"
        ),
    ]
)
