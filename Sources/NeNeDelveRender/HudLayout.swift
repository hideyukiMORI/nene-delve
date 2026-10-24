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
    let labeled = pack(fields(clock, marks: marks, labeled: true), width: width)
    if labeled.complete {
      return labeled.layout
    }
    return pack(fields(clock, marks: marks, labeled: false), width: width).layout
  }

  private struct Field {
    let text: String
    let essential: Bool
  }

  private struct Marks {
    let floor: FloorIndex
    let theme: ThemeName
    let view: ViewMode
  }

  private static func fields(_ clock: HudClock, marks: Marks, labeled: Bool) -> [Field] {
    let total = DigitText.elapsed(clock.elapsed.totalSeconds)
    let stage = DigitText.elapsed(clock.elapsed.stageSeconds)
    let when = DigitText.date(clock.date) + " " + DigitText.clock(clock.time)
    let seed = String(clock.seed.raw)
    if labeled {
      return [
        Field(text: "//FLR:" + ScreenText.floorLabel(marks.floor), essential: true),
        Field(text: "UP:" + total, essential: true),
        Field(text: "STG:" + stage, essential: true),
        Field(text: when, essential: true),
        Field(text: "SEED:" + seed, essential: true),
        Field(text: "SYS:" + ScreenText.themeLine(marks.theme), essential: false),
        Field(text: "MODE:" + ScreenText.viewLine(marks.view), essential: false),
      ]
    }
    return [
      Field(text: ScreenText.floorLabel(marks.floor), essential: true),
      Field(text: total, essential: true),
      Field(text: stage, essential: true),
      Field(text: when, essential: true),
      Field(text: seed, essential: true),
    ]
  }

  private static func pack(_ fields: [Field], width: Int) -> (layout: HudLayout, complete: Bool) {
    var lines = [[String](), [String]()]
    var line = 0
    var complete = true
    for field in fields {
      if place(field, into: &lines, line: &line, width: width) {
        continue
      }
      if field.essential {
        complete = false
      }
    }
    return (HudLayout(first: join(lines[0]), second: join(lines[1])), complete)
  }

  private static func place(
    _ field: Field, into lines: inout [[String]], line: inout Int, width: Int
  )
    -> Bool
  {
    if width <= 0 || field.text.isEmpty {
      return false
    }
    if line < 2, put(field.text, into: &lines[line], width: width) {
      return true
    }
    if line == 0 {
      line = 1
      return put(field.text, into: &lines[line], width: width)
    }
    return false
  }

  private static func put(_ text: String, into line: inout [String], width: Int) -> Bool {
    let next = join(line + [text])
    if next.count > width {
      return false
    }
    line.append(text)
    return true
  }

  private static func join(_ parts: [String]) -> String {
    parts.joined(separator: " ")
  }
}
