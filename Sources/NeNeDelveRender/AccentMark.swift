public struct AccentMark: Equatable, Sendable {
  public let loot: Rgb
  public let water: Rgb
  public let foam: Rgb
  public let threat: Rgb

  public init(loot: Rgb, water: Rgb, foam: Rgb, threat: Rgb) {
    self.loot = loot
    self.water = water
    self.foam = foam
    self.threat = threat
  }
}
