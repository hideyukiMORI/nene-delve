public struct ThemeAccent: Equatable, Sendable {
  public let stairs: Rgb
  public let hud: Rgb

  public init(stairs: Rgb, hud: Rgb) {
    self.stairs = stairs
    self.hud = hud
  }
}
