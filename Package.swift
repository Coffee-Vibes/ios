// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CoffeeVibes",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "CoffeeVibes",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        )
    ]
) 