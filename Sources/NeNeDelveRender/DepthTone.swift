/// 面の色。同じ面は一色で、向きだけ一段暗い。256 色で黒に潰れる色は 95 で止める。
enum DepthTone {
  enum FloorBand {
    case far
    case mid
    case near

    static func at(row: Int, viewHeight: Int) -> FloorBand {
      let height = max(viewHeight, 1)
      let third = max(height / 3, 1)
      if row >= height - third {
        return .near
      }
      if row >= height - (third * 2) {
        return .mid
      }
      return .far
    }
  }

  static func face(_ base: Rgb, vertical: Bool) -> Rgb {
    if vertical {
      return base
    }
    return darkened(base)
  }

  static func edge(_ base: Rgb, vertical: Bool) -> Rgb {
    if vertical {
      return darkened(base)
    }
    return base
  }

  static func ceiling(_ wall: Rgb) -> Rgb {
    let dark = held(wall.dimmed(30))
    if snap(dark) == snap(wall) || snap(dark) == snap(darkened(wall)) {
      return held(stepDown(darkened(wall)))
    }
    return dark
  }

  static func floor(_ base: Rgb, band: FloorBand) -> Rgb {
    switch band {
    case .near:
      base
    case .mid:
      held(base.dimmed(68))
    case .far:
      held(base.dimmed(40))
    }
  }

  static func water(_ color: Rgb) -> Rgb {
    held(color)
  }

  private static func darkened(_ base: Rgb) -> Rgb {
    let half = base.dimmed(50)
    if snap(half) == snap(base) {
      return held(stepDown(base))
    }
    return held(half)
  }

  private static func held(_ color: Rgb) -> Rgb {
    let snapped = snap(color)
    if snapped.red + snapped.green + snapped.blue > 0 {
      return color
    }
    let peak = max(color.red, max(color.green, color.blue))
    if peak == 0 {
      return Rgb(red: 95, green: 95, blue: 95)
    }
    return Rgb(
      red: color.red == peak ? 95 : 0,
      green: color.green == peak ? 95 : 0,
      blue: color.blue == peak ? 95 : 0
    )
  }

  private static func stepDown(_ color: Rgb) -> Rgb {
    Rgb(red: lower(color.red), green: lower(color.green), blue: lower(color.blue))
  }

  private static func lower(_ channel: Int) -> Int {
    let snapped = cube(channel)
    var last = 0
    for step in cubeSteps {
      if step == snapped {
        return last
      }
      last = step
    }
    return 0
  }

  private static func snap(_ color: Rgb) -> Rgb {
    Rgb(red: cube(color.red), green: cube(color.green), blue: cube(color.blue))
  }

  private static func cube(_ channel: Int) -> Int {
    var best = 0
    var gap = Int.max
    for step in cubeSteps {
      let next = abs(channel - step)
      if next < gap {
        best = step
        gap = next
      }
    }
    return best
  }

  private static let cubeSteps = [0, 95, 135, 175, 215, 255]
}
