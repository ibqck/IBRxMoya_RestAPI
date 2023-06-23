// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "IBRxMoya_RestAPI",
    products: [
        .library(name: "IBRxMoya_RestAPI", targets: ["IBRxMoya_RestAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "IBRxMoya_RestAPI",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "Moya", package: "Moya"),
                .product(name: "RxMoya", package: "RxMoya"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON")
            ]
        ),
        .testTarget(
            name: "IBRxMoya_RestAPITests",
            dependencies: ["IBRxMoya_RestAPI"]),
    ]
)

