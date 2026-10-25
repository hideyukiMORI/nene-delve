import NeNeDelveCore

enum HudWords {
  static func piece(_ read: HudRead, _ slot: HudSlot) -> [HudCell] {
    if read.omitted.contains(slot) {
      return []
    }
    let text = written(read, slot)
    if text.isEmpty {
      return []
    }
    return HudCell.glyphs(text, role: role(read, slot), kind: .text)
  }

  static func lost(_ line: DelverLine) -> Int {
    if line.left <= 0 {
      return 0
    }
    return switch line.moment {
    case .pit, .engage:
      line.note
    case .quiet, .descend, .chest, .lake, .kill, .drove, .level, .faint, .low:
      0
    }
  }

  static func travel(_ line: DelverLine) -> Int {
    if line.left <= 0 {
      return DelverLine.span
    }
    return DelverLine.span - line.left
  }

  private static func written(_ read: HudRead, _ slot: HudSlot) -> String {
    let clock = read.brief.clock
    let look = read.brief.look
    return switch slot {
    case .date:
      DigitText.date(clock.date) + " " + DigitText.clock(clock.time)
    case .message:
      DelverCopy.line(read.brief.delver.line)
    case .stage:
      DigitText.elapsed(clock.elapsed.stageSeconds)
    case .elapsed:
      DigitText.elapsed(clock.elapsed.totalSeconds)
    case .place:
      ScreenText.placeLine(look.gaze.place)
    case .level:
      VitalText.level(read.brief.delver.vitals.level)
    case .facing:
      ScreenText.facingLine(look.gaze.facing)
    case .clock:
      DigitText.clock(clock.time)
    case .view:
      ScreenText.viewLine(look.view)
    case .theme:
      ScreenText.themeLine(look.theme)
    case .floor:
      ScreenText.floorLabel(read.brief.floor)
    case .seed:
      "(" + String(clock.seed.raw) + ")"
    case .vitals:
      ""
    }
  }

  private static func role(_ read: HudRead, _ slot: HudSlot) -> HudRole {
    switch slot {
    case .message:
      alarm(read.brief.delver.line.moment)
    case .level:
      levelRole(read)
    case .view, .stage, .theme, .seed, .date:
      .label
    case .floor, .facing, .place, .elapsed, .clock, .vitals:
      .value
    }
  }

  private static func alarm(_ moment: DelverLine.Moment) -> HudRole {
    switch moment {
    case .pit, .engage, .faint, .low:
      .alarm
    case .quiet, .descend, .chest, .lake, .kill, .drove, .level:
      .value
    }
  }

  private static func levelRole(_ read: HudRead) -> HudRole {
    if read.brief.delver.line.moment == .level && read.step.isMultiple(of: 2) {
      return .flash
    }
    return .value
  }
}
