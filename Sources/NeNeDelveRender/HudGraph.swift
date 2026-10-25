enum HudGraph {
  static func draw(
    _ rows: inout [[HudCell]], _ graph: Int, _ samples: [Int],
    _ clock: (cap: Int, step: Int, aim: Bool)
  ) {
    if graph < 0 {
      return
    }
    let values = window(samples)
    var index = 0
    while index < values.count && graph + index < rows[2].count {
      plot(
        &rows, graph + index, (earlier(values, index), values[index], clock.cap),
        (clock.step, index == values.count - 1, clock.aim))
      index += 1
    }
  }

  private static func window(_ samples: [Int]) -> [Int] {
    let kept = samples.count > 11 ? Array(samples.suffix(11)) : samples
    if kept.count >= 11 {
      return kept
    }
    return Array(repeating: kept[0], count: 11 - kept.count) + kept
  }

  private static func earlier(_ values: [Int], _ index: Int) -> Int {
    if index == 0 {
      return values[0]
    }
    return values[index - 1]
  }

  private static func plot(
    _ rows: inout [[HudCell]], _ column: Int, _ point: (Int, Int, Int), _ clock: (Int, Bool, Bool)
  ) {
    if clock.2 {
      aim(&rows, column, point, clock)
      return
    }
    rain(&rows, column, point, clock)
  }

  private static func aim(
    _ rows: inout [[HudCell]], _ column: Int, _ point: (Int, Int, Int), _ clock: (Int, Bool, Bool)
  ) {
    let band = height(point.1, cap: point.2, steps: 4)
    let role = tone((point.0, point.1), clock.0, clock.1, .label)
    rows[2][column] = mark(band >= 4 ? "-" : (band == 3 ? "_" : " "), role: role)
    rows[3][column] = mark(band == 2 ? "-" : (band <= 1 ? "_" : " "), role: role)
  }

  private static func rain(
    _ rows: inout [[HudCell]], _ column: Int, _ point: (Int, Int, Int), _ clock: (Int, Bool, Bool)
  ) {
    let top = height(point.1, cap: point.2, steps: 2) == 2 ? 2 : 3
    let fallen = point.0 - point.1 >= 2
    var row = 2
    while row <= 3 {
      let calm: HudRole =
        row == top
        ? tone((point.0, point.1), clock.0, clock.1, .value) : (fallen ? .alarmSoft : .mid)
      let glyph = row >= top ? HudHash.glyph(column: column, row: row, time: 1) : " "
      rows[row][column] = HudCell(glyph: glyph, role: row >= top ? calm : .faint, kind: .spark)
      row += 1
    }
  }

  private static func tone(_ point: (Int, Int), _ step: Int, _ last: Bool, _ calm: HudRole)
    -> HudRole
  {
    if point.0 - point.1 >= 2 {
      return .alarm
    }
    if last && step / 2 % 2 == 0 {
      return .flash
    }
    return calm
  }

  private static func height(_ value: Int, cap: Int, steps: Int) -> Int {
    if cap <= 0 || value >= cap {
      return cap > 0 ? steps : 0
    }
    return min(steps, max(0, (2 * steps * value) / cap - steps))
  }

  private static func mark(_ glyph: Character, role: HudRole) -> HudCell {
    HudCell(glyph: glyph, role: glyph == " " ? .faint : role, kind: .spark)
  }
}
