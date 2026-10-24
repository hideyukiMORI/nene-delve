import NeNeDelveCore

/// HUD の 3 行。欄は入るか、丸ごと落とす。桁の途中では切らない。
public struct HudLayout: Equatable, Sendable {
  public let first: String
  public let second: String
  public let third: String

  public init(first: String, second: String, third: String) {
    self.first = first
    self.second = second
    self.third = third
  }

  public static func make(clock: HudClock, floor: FloorIndex, look: FrameLook, width: Int)
    -> HudLayout
  {
    let drawn = plate(clock, floor: floor, look: look)
    let omitting = fit(drawn, width: width)
    return packed(drawn, omitting: omitting, width: width)
      ?? HudLayout(first: "", second: "", third: "")
  }

  private struct Plate {
    let floor: String
    let facing: String
    let view: String
    let clock: String
    let place: String
    let elapsed: String
    let stage: String
    let theme: String
    let seed: String
    let date: String
  }

  private struct Wings {
    let open: Character
    let close: Character
  }

  private enum Kind {
    case date
    case place
    case stage
    case elapsed
    case facing
    case clock
    case view
    case theme
    case floor
    case seed
  }

  private static let dropOrder: [Kind] = [
    .date, .place, .stage, .elapsed, .facing, .clock, .view, .theme, .floor, .seed,
  ]

  private static func plate(_ clock: HudClock, floor: FloorIndex, look: FrameLook) -> Plate {
    Plate(
      floor: ScreenText.floorLabel(floor),
      facing: ScreenText.facingLine(look.gaze.facing),
      view: ScreenText.viewLine(look.view),
      clock: DigitText.clock(clock.time),
      place: ScreenText.placeLine(look.gaze.place),
      elapsed: DigitText.elapsed(clock.elapsed.totalSeconds),
      stage: DigitText.elapsed(clock.elapsed.stageSeconds),
      theme: ScreenText.themeLine(look.theme),
      seed: "(" + String(clock.seed.raw) + ")",
      date: DigitText.date(clock.date) + " " + DigitText.clock(clock.time)
    )
  }

  private static func fit(_ drawn: Plate, width: Int) -> Set<Kind> {
    var omitted: Set<Kind> = []
    if packed(drawn, omitting: omitted, width: width) != nil {
      return omitted
    }
    for kind in dropOrder {
      omitted.insert(kind)
      if packed(drawn, omitting: omitted, width: width) != nil {
        return omitted
      }
    }
    return omitted
  }

  private static func packed(_ drawn: Plate, omitting: Set<Kind>, width: Int) -> HudLayout? {
    guard width > 0,
      let head = head(drawn, omitting: omitting, width: width),
      let belt = belt(drawn, omitting: omitting, width: width),
      let foot = foot(drawn, omitting: omitting, width: width)
    else {
      return nil
    }
    return HudLayout(first: head, second: belt, third: foot)
  }

  private static func head(_ drawn: Plate, omitting: Set<Kind>, width: Int) -> String? {
    let left = join(
      [
        token(drawn.floor, kind: .floor, omitting: omitting),
        token(drawn.facing, kind: .facing, omitting: omitting),
        token(drawn.view, kind: .view, omitting: omitting),
      ], gap: "  ")
    let right = token(drawn.clock, kind: .clock, omitting: omitting)
    return cap(left: left, right: right, width: width, wings: Wings(open: "/", close: "/"))
  }

  private static func belt(_ drawn: Plate, omitting: Set<Kind>, width: Int) -> String? {
    let left = join(
      [
        token(drawn.place, kind: .place, omitting: omitting),
        token(drawn.elapsed, kind: .elapsed, omitting: omitting),
        token(drawn.stage, kind: .stage, omitting: omitting),
      ], gap: "   ")
    let right = token(drawn.theme, kind: .theme, omitting: omitting)
    return sides(left: left, right: right, width: width)
  }

  private static func foot(_ drawn: Plate, omitting: Set<Kind>, width: Int) -> String? {
    let left = token(drawn.seed, kind: .seed, omitting: omitting)
    let right = token(drawn.date, kind: .date, omitting: omitting)
    return cap(left: left, right: right, width: width, wings: Wings(open: "\\", close: "\\"))
  }

  private static func token(_ text: String, kind: Kind, omitting: Set<Kind>) -> String {
    if omitting.contains(kind) {
      return ""
    }
    return text
  }

  private static func join(_ parts: [String], gap: String) -> String {
    parts.filter { !$0.isEmpty }.joined(separator: gap)
  }

  private static func cap(left: String, right: String, width: Int, wings: Wings) -> String? {
    if left.isEmpty && right.isEmpty {
      return rule(width, wings: wings)
    }
    if right.isEmpty {
      return bracket(left, width: width, wings: wings)
    }
    if left.isEmpty {
      return bracket(right, width: width, wings: wings)
    }
    return pair(left, right: right, width: width, wings: wings)
  }

  private static func pair(_ left: String, right: String, width: Int, wings: Wings) -> String? {
    let extra = width - 18 - left.count - right.count
    if extra < 0 {
      return nil
    }
    let equals = String(repeating: "=", count: 4 + extra)
    return String(wings.open) + "==[ " + left + " ]" + equals + "[ " + right + " ]=="
      + String(wings.close)
  }

  private static func bracket(_ text: String, width: Int, wings: Wings) -> String? {
    let extra = width - 10 - text.count
    if extra < 0 {
      return nil
    }
    let lead = String(repeating: "=", count: 2 + extra / 2)
    let tail = String(repeating: "=", count: 2 + extra - extra / 2)
    return String(wings.open) + lead + "[ " + text + " ]" + tail + String(wings.close)
  }

  private static func rule(_ width: Int, wings: Wings) -> String? {
    if width < 2 {
      return nil
    }
    return String(wings.open) + String(repeating: "=", count: width - 2) + String(wings.close)
  }

  private static func sides(left: String, right: String, width: Int) -> String? {
    if width < 2 {
      return nil
    }
    if left.isEmpty && right.isEmpty {
      return "|" + String(repeating: " ", count: width - 2) + "|"
    }
    return gutters(left, right: right, width: width)
  }

  private static func gutters(_ left: String, right: String, width: Int) -> String? {
    let gap = width - 4 - left.count - right.count
    if gap < 0 {
      return nil
    }
    if gap < 2 && !left.isEmpty && !right.isEmpty {
      return nil
    }
    return "| " + left + String(repeating: " ", count: gap) + right + " |"
  }
}
