// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "IBRxMoya_RestAPI",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "IBRxMoya_RestAPI",
            targets: ["IBRxMoya_RestAPI"]),
    ],
    dependencies: [
        //.package(url: "https://github.com/ibqck/IBRxMoya_RestAPI", from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IBRxMoya_RestAPI"),
        .testTarget(
            name: "IBRxMoya_RestAPITests",
            dependencies: ["IBRxMoya_RestAPI"]),
    ]
)
