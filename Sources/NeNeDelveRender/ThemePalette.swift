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
      wall: Rgb(red: 0, green: 150, blue: 170),
      floor: Rgb(red: 120, green: 255, blue: 245),
      runner: Rgb(red: 255, green: 70, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 255),
      hud: Rgb(red: 0, green: 255, blue: 255),
      chip: Rgb(red: 72, green: 0, blue: 84),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 186, blue: 48),
        water: Rgb(red: 0, green: 60, blue: 120),
        foam: Rgb(red: 190, green: 235, blue: 255)
      )
    )
  )
}
