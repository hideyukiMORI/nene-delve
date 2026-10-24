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
    case .phosphor:
      phosphor
    case .amberTerm:
      amberTerm
    case .iceCore:
      iceCore
    case .synthwave:
      synthwave
    case .deepSea:
      deepSea
    case .void:
      void
    case .toxic:
      toxic
    case .aurora:
      aurora
    case .carbon:
      carbon
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
        foam: Rgb(red: 190, green: 235, blue: 255),
        threat: Rgb(red: 255, green: 64, blue: 96)
      )
    )
  )

  private static let phosphor = ThemePalette(
    name: .phosphor,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 0, blue: 0),
      wall: Rgb(red: 0, green: 140, blue: 40),
      floor: Rgb(red: 140, green: 255, blue: 160),
      runner: Rgb(red: 190, green: 255, blue: 90)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 220, green: 255, blue: 220),
      hud: Rgb(red: 80, green: 255, blue: 120),
      chip: Rgb(red: 0, green: 40, blue: 0),
      mark: AccentMark(
        loot: Rgb(red: 220, green: 255, blue: 80),
        water: Rgb(red: 0, green: 50, blue: 28),
        foam: Rgb(red: 180, green: 255, blue: 190),
        threat: Rgb(red: 255, green: 90, blue: 40)
      )
    )
  )

  private static let amberTerm = ThemePalette(
    name: .amberTerm,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 0, blue: 0),
      wall: Rgb(red: 180, green: 100, blue: 0),
      floor: Rgb(red: 255, green: 176, blue: 60),
      runner: Rgb(red: 255, green: 214, blue: 120)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 236, blue: 200),
      hud: Rgb(red: 255, green: 160, blue: 40),
      chip: Rgb(red: 64, green: 28, blue: 0),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 220, blue: 140),
        water: Rgb(red: 84, green: 36, blue: 0),
        foam: Rgb(red: 255, green: 196, blue: 110),
        threat: Rgb(red: 255, green: 80, blue: 20)
      )
    )
  )

  private static let iceCore = ThemePalette(
    name: .iceCore,
    ink: ThemeInk(
      background: Rgb(red: 4, green: 10, blue: 28),
      wall: Rgb(red: 120, green: 180, blue: 220),
      floor: Rgb(red: 210, green: 240, blue: 255),
      runner: Rgb(red: 240, green: 252, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 255),
      hud: Rgb(red: 160, green: 220, blue: 255),
      chip: Rgb(red: 8, green: 28, blue: 52),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 214, blue: 120),
        water: Rgb(red: 0, green: 40, blue: 90),
        foam: Rgb(red: 190, green: 230, blue: 255),
        threat: Rgb(red: 255, green: 90, blue: 110)
      )
    )
  )

  private static let synthwave = ThemePalette(
    name: .synthwave,
    ink: ThemeInk(
      background: Rgb(red: 16, green: 0, blue: 32),
      wall: Rgb(red: 255, green: 60, blue: 160),
      floor: Rgb(red: 255, green: 150, blue: 220),
      runner: Rgb(red: 80, green: 255, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 255),
      hud: Rgb(red: 255, green: 80, blue: 180),
      chip: Rgb(red: 48, green: 0, blue: 64),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 200, blue: 80),
        water: Rgb(red: 40, green: 0, blue: 80),
        foam: Rgb(red: 255, green: 160, blue: 220),
        threat: Rgb(red: 255, green: 40, blue: 80)
      )
    )
  )

  private static let deepSea = ThemePalette(
    name: .deepSea,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 8, blue: 16),
      wall: Rgb(red: 0, green: 120, blue: 140),
      floor: Rgb(red: 80, green: 220, blue: 200),
      runner: Rgb(red: 180, green: 255, blue: 220)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 220, green: 255, blue: 240),
      hud: Rgb(red: 0, green: 200, blue: 180),
      chip: Rgb(red: 0, green: 32, blue: 40),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 190, blue: 70),
        water: Rgb(red: 0, green: 36, blue: 70),
        foam: Rgb(red: 160, green: 230, blue: 220),
        threat: Rgb(red: 255, green: 70, blue: 90)
      )
    )
  )

  private static let void = ThemePalette(
    name: .void,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 0, blue: 0),
      wall: Rgb(red: 150, green: 150, blue: 150),
      floor: Rgb(red: 220, green: 220, blue: 220),
      runner: Rgb(red: 255, green: 255, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 255),
      hud: Rgb(red: 200, green: 200, blue: 200),
      chip: Rgb(red: 32, green: 32, blue: 32),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 255, blue: 255),
        water: Rgb(red: 36, green: 36, blue: 36),
        foam: Rgb(red: 190, green: 190, blue: 190),
        threat: Rgb(red: 255, green: 255, blue: 255)
      )
    )
  )

  private static let toxic = ThemePalette(
    name: .toxic,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 0, blue: 0),
      wall: Rgb(red: 140, green: 200, blue: 0),
      floor: Rgb(red: 210, green: 255, blue: 40),
      runner: Rgb(red: 255, green: 255, blue: 80)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 255, green: 255, blue: 200),
      hud: Rgb(red: 180, green: 255, blue: 0),
      chip: Rgb(red: 24, green: 36, blue: 0),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 180, blue: 0),
        water: Rgb(red: 16, green: 40, blue: 0),
        foam: Rgb(red: 200, green: 255, blue: 80),
        threat: Rgb(red: 255, green: 48, blue: 40)
      )
    )
  )

  private static let aurora = ThemePalette(
    name: .aurora,
    ink: ThemeInk(
      background: Rgb(red: 0, green: 4, blue: 12),
      wall: Rgb(red: 40, green: 200, blue: 140),
      floor: Rgb(red: 180, green: 140, blue: 255),
      runner: Rgb(red: 140, green: 255, blue: 210)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 240, green: 255, blue: 255),
      hud: Rgb(red: 80, green: 255, blue: 180),
      chip: Rgb(red: 16, green: 0, blue: 32),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 200, blue: 80),
        water: Rgb(red: 0, green: 30, blue: 52),
        foam: Rgb(red: 170, green: 255, blue: 220),
        threat: Rgb(red: 255, green: 60, blue: 120)
      )
    )
  )

  private static let carbon = ThemePalette(
    name: .carbon,
    ink: ThemeInk(
      background: Rgb(red: 12, green: 12, blue: 14),
      wall: Rgb(red: 70, green: 96, blue: 120),
      floor: Rgb(red: 180, green: 200, blue: 220),
      runner: Rgb(red: 80, green: 170, blue: 255)
    ),
    accent: ThemeAccent(
      stairs: Rgb(red: 230, green: 240, blue: 255),
      hud: Rgb(red: 80, green: 160, blue: 255),
      chip: Rgb(red: 20, green: 26, blue: 34),
      mark: AccentMark(
        loot: Rgb(red: 255, green: 186, blue: 48),
        water: Rgb(red: 10, green: 24, blue: 42),
        foam: Rgb(red: 160, green: 200, blue: 230),
        threat: Rgb(red: 255, green: 70, blue: 90)
      )
    )
  )
}
