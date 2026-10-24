import NeNeDelveCore

/// HUD の 2 行。欄は入るか、丸ごと落とす。桁の途中では切らない。
public struct HudLayout: Equatable, Sendable {
  public let first: String
  public let second: String

  public init(first: String, second: String) {
    self.first = first
    self.second = second
  }

  public static func make(clock: HudClock, floor: FloorIndex, look: FrameLook, width: Int)
    -> HudLayout
  {
    let marks = Marks(floor: floor, theme: look.theme, view: look.view)
    let omitting = fit(clock, marks: marks, width: width)
    return aligned(clock, marks: marks, omitting: omitting, width: width)
      ?? HudLayout(first: "", second: "")
  }

  private struct Marks {
    let floor: FloorIndex
    let theme: ThemeName
    let view: ViewMode
  }

  private enum Kind {
    case floor
    case elapsed
    case stage
    case date
    case view
    case seed
    case theme
  }

  private static let dropOrder: [Kind] = [
    .date, .theme, .stage, .elapsed, .view, .floor, .seed,
  ]

  private static func fit(_ clock: HudClock, marks: Marks, width: Int) -> Set<Kind> {
    var omitted: Set<Kind> = []
    if rowFits(clock, marks: marks, omitting: omitted, width: width) {
      return omitted
    }
    for kind in dropOrder {
      omitted.insert(kind)
      if rowFits(clock, marks: marks, omitting: omitted, width: width) {
        return omitted
      }
    }
    return omitted
  }

  private static func rowFits(_ clock: HudClock, marks: Marks, omitting: Set<Kind>, width: Int)
    -> Bool
  {
    aligned(clock, marks: marks, omitting: omitting, width: width) != nil
  }

  private static func aligned(
    _ clock: HudClock, marks: Marks, omitting: Set<Kind>, width: Int
  ) -> HudLayout? {
    let mode = omitting.contains(.view) ? "" : ScreenText.viewLine(marks.view)
    let seed = omitting.contains(.seed) ? "" : "(" + String(clock.seed.raw) + ")"
    let theme = omitting.contains(.theme) ? "" : ScreenText.themeLine(marks.theme)
    guard
      let first = row(
        left: cluster(clock, marks: marks, omitting: omitting), right: mode, width: width),
      let second = row(left: seed, right: theme, width: width)
    else {
      return nil
    }
    return HudLayout(first: first, second: second)
  }

  private static func cluster(_ clock: HudClock, marks: Marks, omitting: Set<Kind>) -> String {
    var parts: [String] = []
    if !omitting.contains(.floor) {
      parts.append(ScreenText.floorLabel(marks.floor))
    }
    if !omitting.contains(.elapsed) {
      parts.append(DigitText.elapsed(clock.elapsed.totalSeconds))
    }
    if !omitting.contains(.stage) {
      parts.append(DigitText.elapsed(clock.elapsed.stageSeconds))
    }
    if !omitting.contains(.date) {
      parts.append(DigitText.date(clock.date) + " " + DigitText.clock(clock.time))
    }
    return parts.joined(separator: "  ")
  }

  private static func row(left: String, right: String, width: Int) -> String? {
    if width <= 0 {
      return nil
    }
    if right.isEmpty {
      if left.count > width {
        return nil
      }
      return left
    }
    if left.isEmpty {
      if right.count > width {
        return nil
      }
      return String(repeating: " ", count: width - right.count) + right
    }
    let gap = width - left.count - right.count
    if gap < 2 {
      return nil
    }
    return left + String(repeating: " ", count: gap) + right
  }
}
