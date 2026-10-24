public struct ThemeAccent: Equatable, Sendable {
  public let stairs: Rgb
  public let hud: Rgb
  public let chip: Rgb
  public let loot: Rgb

  public init(stairs: Rgb, hud: Rgb, chip: Rgb, loot: Rgb) {
    self.stairs = stairs
    self.hud = hud
    self.chip = chip
    self.loot = loot
  }
}
