import Testing

@testable import NeNeDelveRender

struct HudToneTests {
  @Test func everyRoleStaysReadableOnEveryTheme() {
    for name in themes {
      let palette = ThemePalette.palette(name)
      let ground = palette.ink.background
      let value = HudTone.ink(.value, palette: palette)
      let faint = HudTone.ink(.faint, palette: palette)
      let alarm = HudTone.ink(.alarm, palette: palette)
      #expect(contrast(value, ground) >= 4.5)
      #expect(contrast(faint, ground) >= 4.5)
      #expect(contrast(alarm, ground) >= 4.5)
      #expect(contrast(value, ground) > contrast(faint, ground))
      #expect(contrast(HudTone.ink(.label, palette: palette), ground) >= 4.5)
      #expect(contrast(HudTone.ink(.alarmSoft, palette: palette), ground) >= 4.5)
    }
  }

  private var themes: [ThemeName] {
    [
      .neonGrid, .phosphor, .amberTerm, .iceCore, .synthwave, .deepSea, .void, .toxic, .aurora,
      .carbon,
    ]
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
