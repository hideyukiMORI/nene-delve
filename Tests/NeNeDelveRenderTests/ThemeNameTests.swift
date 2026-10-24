import Testing

@testable import NeNeDelveRender

struct ThemeNameTests {
  @Test func tenThemesCycleAndThePreviousStepReturns() {
    let names = [
      "NEON GRID", "PHOSPHOR", "AMBER TERM", "ICE CORE", "SYNTHWAVE", "DEEP SEA", "VOID",
      "TOXIC", "AURORA", "CARBON",
    ]
    var theme = ThemeName.neonGrid
    var seen: [String] = []
    for name in names {
      #expect(ScreenText.themeLine(theme) == name)
      let forward = theme.next()
      #expect(forward.previous() == theme)
      seen.append(ScreenText.themeLine(theme))
      theme = forward
    }
    #expect(theme == .neonGrid)
    #expect(seen == names)
  }

  @Test func phosphorWallsAreNotNeon() {
    let neon = ThemePalette.palette(.neonGrid)
    let phosphor = ThemePalette.palette(.phosphor)
    #expect(phosphor.ink.wall != neon.ink.wall)
    #expect(phosphor.ink.background == neon.ink.background)
    #expect(ThemePalette.palette(.void).ink.wall.red == ThemePalette.palette(.void).ink.wall.green)
  }
}
