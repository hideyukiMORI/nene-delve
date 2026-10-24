/// HUD の字色。地はテーマ背景。暗い字は地に対して 4.5:1 を割らない。
enum HudTone {
  struct Mark {
    let glyph: Character
    let row: Int
    let column: Int
    let line: String
  }

  static func foreground(_ mark: Mark, palette: ThemePalette) -> Rgb {
    if quiet(mark) {
      return softened(palette.accent.hud, on: palette.ink.background)
    }
    return palette.accent.hud
  }

  private static func quiet(_ mark: Mark) -> Bool {
    if mark.row == 1 {
      return !mark.glyph.isNumber
    }
    return floorMark(mark)
  }

  private static func floorMark(_ mark: Mark) -> Bool {
    if mark.row != 0 || !mark.line.hasPrefix("B") {
      return false
    }
    guard let fence = mark.line.firstIndex(of: "F") else {
      return false
    }
    let end = mark.line.distance(from: mark.line.startIndex, to: fence)
    return mark.column == 0 || mark.column == end
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

  private static func channel(_ value: Int) -> Double {
    let unit = Double(value) / 255
    if unit <= 0.04045 {
      return unit / 12.92
    }
    // u^3 は sRGB の 2.4 乗より暗い。ここで 4.5 を超える色は、実測の比でも 4.5 を超える。
    return unit * unit * unit
  }
}
