/// HUD の字色。地はテーマ背景。どの段も地に対して 4.5 を割らない。
enum HudTone {
  static func ink(_ role: HudRole, palette: ThemePalette) -> Rgb {
    let ground = palette.ink.background
    let hud = palette.accent.hud
    return switch role {
    case .value:
      hud
    case .flash:
      readable(palette.ink.floor, on: ground, else: hud)
    case .alarm:
      readable(palette.accent.mark.threat, on: ground, else: hud)
    case .label:
      shade(hud, on: ground, percent: 80)
    case .firm:
      shade(hud, on: ground, percent: 65)
    case .mid:
      shade(hud, on: ground, percent: 50)
    case .soft:
      shade(hud, on: ground, percent: 40)
    case .faint:
      shade(hud, on: ground, percent: 25)
    case .alarmSoft:
      shade(palette.accent.mark.threat, on: ground, percent: 70)
    }
  }

  private static func readable(_ ink: Rgb, on ground: Rgb, else fallback: Rgb) -> Rgb {
    if contrast(ink, ground) >= 4.5 {
      return ink
    }
    return fallback
  }

  private static func shade(_ ink: Rgb, on ground: Rgb, percent: Int) -> Rgb {
    let sample = ink.dimmed(percent)
    if contrast(sample, ground) >= 4.5 {
      return sample
    }
    return softened(ink, on: ground)
  }

  private static func softened(_ ink: Rgb, on ground: Rgb) -> Rgb {
    var best = ink
    var kept = 100
    while kept >= 25 {
      let sample = ink.dimmed(kept)
      if contrast(sample, ground) >= 4.5 {
        best = sample
      }
      kept -= 5
    }
    return best
  }

  private static func contrast(_ ink: Rgb, _ ground: Rgb) -> Double {
    let lighter = max(luminance(ink), luminance(ground))
    let darker = min(luminance(ink), luminance(ground))
    return (lighter + 0.05) / (darker + 0.05)
  }

  private static func luminance(_ color: Rgb) -> Double {
    let red = channel(color.red)
    let green = channel(color.green)
    let blue = channel(color.blue)
    return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  }

  /// u^3 は実測のガンマ 2.4 より明るい。ここを通る 4.5 は実測でも 4.5 を割らない。
  private static func channel(_ value: Int) -> Double {
    let unit = Double(value) / 255
    if unit <= 0.04045 {
      return unit / 12.92
    }
    return unit * unit * unit
  }
}
