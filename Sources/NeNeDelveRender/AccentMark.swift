public struct AccentMark: Equatable, Sendable {
  public let loot: Rgb
  public let water: Rgb
  public let foam: Rgb

  public init(loot: Rgb, water: Rgb, foam: Rgb) {
    self.loot = loot
    self.water = water
    self.foam = foam
  }
}
