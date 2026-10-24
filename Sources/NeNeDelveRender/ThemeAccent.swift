public struct ThemeAccent: Equatable, Sendable {
  public let stairs: Rgb
  public let hud: Rgb
  public let chip: Rgb
  public let mark: AccentMark

  public init(stairs: Rgb, hud: Rgb, chip: Rgb, mark: AccentMark) {
    self.stairs = stairs
    self.hud = hud
    self.chip = chip
    self.mark = mark
  }
}
