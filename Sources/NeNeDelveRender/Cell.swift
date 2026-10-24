public struct Cell: Equatable, Sendable {
  public let glyph: Character
  public let foreground: Rgb
  public let background: Rgb

  public init(glyph: Character, foreground: Rgb, background: Rgb) {
    self.glyph = glyph
    self.foreground = foreground
    self.background = background
  }
}
