// swift-tools-version: 5.10.0
import PackageDescription

let package = Package(
  name: "mdScriptFilter",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
  ],
  targets: [
    .executableTarget(
      name: "mdscriptfilter",
      dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")])
  ]
)
