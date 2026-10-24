public struct ThemeAccent: Equatable, Sendable {
  public let stairs: Rgb
  public let hud: Rgb
  public let chip: Rgb

  public init(stairs: Rgb, hud: Rgb, chip: Rgb) {
    self.stairs = stairs
    self.hud = hud
    self.chip = chip
  }
}
