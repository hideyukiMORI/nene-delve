// swift-tools-version: 6.2
import PackageDescription

let strictSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
  name: "nene-delve",
  targets: [
    .target(
      name: "NeNeDelveCore",
      dependencies: [],
      swiftSettings: strictSettings
    ),
    .target(
      name: "NeNeDelveRender",
      dependencies: ["NeNeDelveCore"],
      swiftSettings: strictSettings
    ),
    .target(
      name: "NeNeDelveTerminal",
      dependencies: ["NeNeDelveRender"],
      swiftSettings: strictSettings
    ),
    .executableTarget(
      name: "nene-delve",
      dependencies: ["NeNeDelveCore", "NeNeDelveRender", "NeNeDelveTerminal"],
      swiftSettings: strictSettings
    ),
    .testTarget(
      name: "NeNeDelveCoreTests",
      dependencies: ["NeNeDelveCore"]
    ),
    .testTarget(
      name: "NeNeDelveRenderTests",
      dependencies: ["NeNeDelveRender"]
    ),
    .testTarget(
      name: "NeNeDelveTerminalTests",
      dependencies: ["NeNeDelveTerminal"]
    ),
  ]
)
