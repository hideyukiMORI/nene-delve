import Testing

@testable import NeNeDelveRender

struct HudToneTests {
  @Test func quietInkStaysReadableOnEveryTheme() {
    for name in themes {
      let palette = ThemePalette.palette(name)
      let quiet = HudTone.foreground(mark("B", line: "B1F"), palette: palette)
      let ratio = contrast(quiet, palette.ink.background)
      #expect(ratio >= 4.5)
    }
  }

  private var themes: [ThemeName] {
    [
      .neonGrid, .phosphor, .amberTerm, .iceCore, .synthwave, .deepSea, .void, .toxic, .aurora,
      .carbon,
    ]
  }

  private func mark(_ glyph: Character, line: String) -> HudTone.Mark {
    HudTone.Mark(glyph: glyph, row: 0, column: 0, line: line)
  }

  private func contrast(_ ink: Rgb, _ ground: Rgb) -> Double {
    let lighter = max(luminance(ink), luminance(ground))
    let darker = min(luminance(ink), luminance(ground))
    return (lighter + 0.05) / (darker + 0.05)
  }

  private func luminance(_ color: Rgb) -> Double {
    let red = channel(color.red)
    let green = channel(color.green)
    let blue = channel(color.blue)
    return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  }

  private func channel(_ value: Int) -> Double {
    let unit = Double(value) / 255
    if unit <= 0.04045 {
      return unit / 12.92
    }
    return unit * unit * unit
  }
}
