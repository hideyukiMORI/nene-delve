public struct ThemePalette: Equatable, Sendable {
  public let name: ThemeName
  public let ink: ThemeInk
  public let accent: ThemeAccent

  public init(name: ThemeName, ink: ThemeInk, accent: ThemeAccent) {
    self.name = name
    self.ink = ink
    self.accent = accent
  }

  public var blank: Cell {
    Cell(glyph: " ", foreground: accent.hud, background: ink.background)
  }

  public static func palette(_ name: ThemeName) -> ThemePalette {
    switch name {
    case .neonGrid:
      neonGrid
    }
  }

  private static let neonGrid = ThemePalette(
    name: .neonGrid,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 0, blue: 0),
      wall: Rgb(red: 0, green: 255, blue: 255),
      floor: Rgb(red: 0, green: 40, blue: 48),
      runner: Rgb(red: 255, green: 0, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 255),
      hud: Rgb(red: 0, green: 255, blue: 255)
    )
  )
}
