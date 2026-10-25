enum HudNeedle {
  static func rows(_ marks: Int, _ value: Int, _ cap: Int, _ hurt: (lost: Int, travel: Int))
    -> [[HudCell]]
  {
    let toward = at(value, marks: marks, cap: cap)
    let from = at(value + hurt.lost, marks: marks, cap: cap)
    let seated = seat(toward, from, hurt.lost, hurt.travel)
    var upper: [HudCell] = []
    var lower: [HudCell] = []
    var index = 0
    while index < marks {
      upper.append(
        upperMark(index, position: seated.position, role: seated.role, lock: seated.lock))
      lower.append(lowerMark(index, position: seated.position, role: seated.role))
      index += 1
    }
    return [upper, lower]
  }

  private static func seat(_ toward: Int, _ from: Int, _ lost: Int, _ travel: Int) -> (
    position: Int, role: HudRole, lock: Bool
  ) {
    if lost <= 0 {
      return (toward, .value, false)
    }
    let shifted = min(max(travel, 0), 5)
    let position = from + (toward - from) * shifted / 5
    return (position, travel < 9 ? .alarm : .value, travel < 7)
  }

  private static func at(_ value: Int, marks: Int, cap: Int) -> Int {
    if cap <= 0 || marks <= 1 {
      return 0
    }
    let clamped = min(max(value, 0), cap)
    return (clamped * (marks - 1) + cap / 2) / cap
  }

  private static func upperMark(_ index: Int, position: Int, role: HudRole, lock: Bool) -> HudCell {
    if index == position {
      return HudCell(glyph: "v", role: role, kind: .gauge)
    }
    if lock && index == position - 1 {
      return HudCell(glyph: ">", role: role, kind: .gauge)
    }
    if lock && index == position + 1 {
      return HudCell(glyph: "<", role: role, kind: .gauge)
    }
    let glyph: Character = index % 4 == 3 ? "." : " "
    return HudCell(glyph: glyph, role: .faint, kind: .gauge)
  }

  private static func lowerMark(_ index: Int, position: Int, role: HudRole) -> HudCell {
    if index == position {
      return HudCell(glyph: "|", role: role, kind: .gauge)
    }
    if index < position {
      return HudCell(glyph: "=", role: .mid, kind: .gauge)
    }
    let glyph: Character = index % 4 == 3 ? "+" : "."
    return HudCell(glyph: glyph, role: .soft, kind: .gauge)
  }
}
