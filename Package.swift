// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Squirrel",
    platforms: [
      .iOS(.v16),
      .macOS(.v13),
    ],
    products: [
        .library(
            name: "Squirrel",
            targets: [
                "Squirrel"
            ]
        ),
        .library(
            name: "SquirrelUI",
            targets: [
                "SquirrelUI"
            ]
        ),
    ]
)

// MARK: - Squirrel

package.targets.append(contentsOf: [
    Target
        .target(
            name: "Squirrel",
            dependencies: [
            ],
            path: "Sources/Squirrel"
        ),
        .testTarget(
            name: "SquirrelTests",
            dependencies: [
                "Squirrel"
            ],
            path: "Tests/Squirrel"
        ),
    ]
)

// MARK: - SquirrelUI

package.targets.append(contentsOf: [
    Target
        .target(
            name: "SquirrelUI",
            dependencies: [
                "Squirrel"
            ],
            path: "Sources/SquirrelUI"
        ),
        .testTarget(
            name: "SquirrelUITests",
            dependencies: [
                "SquirrelUI"
            ],
            path: "Tests/SquirrelUI"
        ),
    ]
)
