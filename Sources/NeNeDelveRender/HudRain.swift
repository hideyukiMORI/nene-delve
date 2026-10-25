enum HudRain {
  static func overlay(_ draft: HudDraft, _ read: HudRead) -> [[HudCell]] {
    var rows = draft.rows
    extend(&rows)
    var column = 0
    while column < rows[0].count {
      if meter(rows[2][column].kind) {
        paint(&rows, column, read.step)
      } else {
        drip(&rows, column, read.step)
      }
      column += 1
    }
    let clock = (read.brief.delver.vitals.hitMax, read.step, false)
    HudGraph.draw(&rows, draft.graph, HudSamples.values(read), clock)
    return rows
  }

  private static func extend(_ rows: inout [[HudCell]]) {
    var column = 0
    while column < rows[2].count {
      let kind = rows[2][column].kind
      if meter(kind) {
        lift(&rows, column, kind)
      }
      column += 1
    }
  }

  private static func lift(_ rows: inout [[HudCell]], _ column: Int, _ kind: HudKind) {
    var row = 0
    while row < 2 {
      let cell = rows[row][column]
      if open(cell.kind) && !HudNear.text(rows[row], column) {
        rows[row][column] = HudCell(glyph: " ", role: .faint, kind: kind)
      }
      row += 1
    }
  }

  private static func paint(_ rows: inout [[HudCell]], _ column: Int, _ step: Int) {
    var row = 0
    while row < 4 {
      if meter(rows[row][column].kind) {
        rows[row][column] = stream(column, row, step, rows[row][column].kind)
      }
      row += 1
    }
  }

  private static func drip(_ rows: inout [[HudCell]], _ column: Int, _ step: Int) {
    if HudHash.mix(column: column, row: 7, time: 0) % 4 != 0 {
      return
    }
    let head = (step + Int(HudHash.mix(column: column, row: 9, time: 0) % 7)) % 7
    var row = 0
    while row < 4 {
      let back = head - row
      let cell = rows[row][column]
      if back >= 0 && back <= 2 && open(cell.kind) && !HudNear.text(rows[row], column) {
        rows[row][column] = drop(column, row, step - back, back)
      }
      row += 1
    }
  }

  private static func stream(_ column: Int, _ row: Int, _ step: Int, _ kind: HudKind) -> HudCell {
    let phase = step % 28
    let cooled = cool(kind, phase)
    let period = cooled == .dead ? 7 : 5
    let head = (step + Int(HudHash.mix(column: column, row: 3, time: 0))) % period
    let back = head - row
    let roles = tones(cooled, phase)
    if back >= 0 && back < roles.count {
      let glyph = HudHash.glyph(column: column, row: row, time: step - back)
      return HudCell(glyph: glyph, role: roles[back], kind: .live)
    }
    if cooled == .live && row >= 2 {
      let glyph = HudHash.glyph(column: column, row: row, time: step / 3)
      return HudCell(glyph: glyph, role: .mid, kind: .live)
    }
    return HudCell(glyph: " ", role: .faint, kind: kind)
  }

  private static func drop(_ column: Int, _ row: Int, _ time: Int, _ back: Int) -> HudCell {
    let role: HudRole = back == 0 ? .firm : (back == 1 ? .mid : .soft)
    return HudCell(
      glyph: HudHash.glyph(column: column, row: row, time: time), role: role, kind: .blank)
  }

  private static func cool(_ kind: HudKind, _ phase: Int) -> HudKind {
    if kind == .lost && phase >= 18 {
      return .dead
    }
    return kind
  }

  private static func tones(_ kind: HudKind, _ phase: Int) -> [HudRole] {
    switch kind {
    case .live:
      [.flash, .value, .label]
    case .lost:
      phase < 10 ? [.alarm, .alarm, .alarmSoft] : [.alarmSoft, .faint, .faint]
    case .dead, .text, .blank, .frame, .spark, .gauge:
      [.soft]
    }
  }

  private static func meter(_ kind: HudKind) -> Bool {
    switch kind {
    case .live, .lost, .dead:
      true
    case .text, .blank, .frame, .spark, .gauge:
      false
    }
  }

  private static func open(_ kind: HudKind) -> Bool {
    kind == .blank || kind == .frame
  }
}
