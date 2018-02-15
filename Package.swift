// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DispatchSocketIssue",
    products: [
        .library(name: "DispatchSocketIssue", targets: ["DispatchSocketIssue"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "DispatchSocketIssue", dependencies: []),
        .target(name: "test1", dependencies: ["DispatchSocketIssue"]),
        .target(name: "test2", dependencies: ["DispatchSocketIssue"]),
        .target(name: "test3", dependencies: ["DispatchSocketIssue"]),
        .target(name: "test4", dependencies: ["DispatchSocketIssue"]),
        .testTarget(name: "DispatchSocketIssueTests", dependencies: ["DispatchSocketIssue"]),
    ]
)
