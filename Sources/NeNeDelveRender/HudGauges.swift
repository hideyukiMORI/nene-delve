import NeNeDelveCore

enum HudGauges {
  static func chosen(_ read: HudRead, aim: Bool) -> [[HudCell]] {
    if read.omitted.contains(.vitals) {
      return [[], []]
    }
    let wide = form(read, aim: aim, marks: [10, 6, 8], gap: 2)
    if fits(read, form: wide) {
      return wide
    }
    let middle = form(read, aim: aim, marks: [3, 2, 2], gap: 1)
    if fits(read, form: middle) {
      return middle
    }
    return form(read, aim: aim, marks: [3], gap: 1)
  }

  private static func fits(_ read: HudRead, form: [[HudCell]]) -> Bool {
    let theme = HudWords.piece(read, .theme).count
    let gap = read.width >= 60 ? 3 : 2
    let extra = theme > 0 ? theme + gap : 0
    let sides = read.width >= 60 ? 6 : 2
    return sides + form[0].count + extra <= read.width
  }

  private static func form(_ read: HudRead, aim: Bool, marks: [Int], gap: Int) -> [[HudCell]] {
    var upper: [HudCell] = []
    var lower: [HudCell] = []
    for index in marks.indices {
      if index > 0 {
        upper.append(contentsOf: HudCell.spaces(gap))
        lower.append(contentsOf: HudCell.spaces(gap))
      }
      let piece = meter(read, aim: aim, index: index, marks: marks[index])
      upper.append(contentsOf: piece[0])
      lower.append(contentsOf: piece[1])
    }
    return [upper, lower]
  }

  private static func meter(_ read: HudRead, aim: Bool, index: Int, marks: Int) -> [[HudCell]] {
    let label = HudCell.glyphs(name(index) + " ", role: .label, kind: .text)
    let number = HudCell.glyphs(
      digits(read, index: index), role: numberRole(read, index: index), kind: .text)
    let drawn = figure(read, aim: aim, index: index, marks: marks)
    return [
      label + drawn[0] + number,
      HudCell.spaces(label.count) + drawn[1] + HudCell.spaces(number.count),
    ]
  }

  private static func figure(_ read: HudRead, aim: Bool, index: Int, marks: Int) -> [[HudCell]] {
    let vitals = read.brief.delver.vitals
    let value = amount(vitals, index: index)
    let cap = limit(vitals, index: index)
    let lost = index == 0 ? HudWords.lost(read.brief.delver.line) : 0
    if aim {
      return HudNeedle.rows(marks, value, cap, (lost, HudWords.travel(read.brief.delver.line)))
    }
    return rain(marks, value, cap, lost)
  }

  private static func rain(_ marks: Int, _ value: Int, _ cap: Int, _ lost: Int) -> [[HudCell]] {
    let live = cap > 0 ? min(marks, (value * marks + cap - 1) / cap) : 0
    let before = lost > 0 ? min(marks, ((value + lost) * marks + cap - 1) / cap) : live
    var cells: [HudCell] = []
    var index = 0
    while index < marks {
      cells.append(HudCell(glyph: " ", role: .faint, kind: kind(index, live: live, before: before)))
      index += 1
    }
    return [cells, cells]
  }

  private static func kind(_ index: Int, live: Int, before: Int) -> HudKind {
    if index < live {
      return .live
    }
    if index < before {
      return .lost
    }
    return .dead
  }

  private static func name(_ index: Int) -> String {
    if index == 0 {
      return "HP"
    }
    if index == 1 {
      return "MP"
    }
    return "EXP"
  }

  private static func amount(_ vitals: DelverVitals, index: Int) -> Int {
    if index == 0 {
      return vitals.hitPoints
    }
    if index == 1 {
      return vitals.magicPoints
    }
    return vitals.experience
  }

  private static func limit(_ vitals: DelverVitals, index: Int) -> Int {
    if index == 0 {
      return vitals.hitMax
    }
    if index == 1 {
      return vitals.magicMax
    }
    return vitals.experienceGoal
  }

  private static func digits(_ read: HudRead, index: Int) -> String {
    " " + DigitText.padded(amount(read.brief.delver.vitals, index: index), width: 2)
  }

  private static func numberRole(_ read: HudRead, index: Int) -> HudRole {
    let line = read.brief.delver.line
    if index == 0 && HudWords.lost(line) > 0 && HudWords.travel(line) < 18 {
      return .alarm
    }
    return .label
  }
}
