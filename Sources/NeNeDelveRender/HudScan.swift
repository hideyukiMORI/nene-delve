enum HudScan {
  static func lay(_ rows: inout [[HudCell]], column: Int, through: Bool) {
    let marks: [(Int, Character, HudRole)] = [
      (1, ">", .mid), (0, "|", .firm), (-1, "=", .mid), (-2, "-", .soft), (-3, "-", .soft),
      (-4, ".", .faint),
    ]
    for mark in marks {
      put(rows: &rows, column: column + mark.0, glyph: mark.1, role: mark.2)
    }
    if through {
      drop(rows: &rows, column: column)
    }
  }

  static func sweep(_ width: Int, step: Int) -> Int {
    let loop = 14
    let stride = (width + 8 + loop - 1) / loop
    return -2 + HudBeat.wrapped(step, loop) * stride
  }

  private static func put(
    rows: inout [[HudCell]], column: Int, glyph: Character, role: HudRole
  ) {
    if column < 0 || column >= rows[0].count {
      return
    }
    rows[0][column] = HudCell(glyph: glyph, role: role, kind: .blank)
  }

  private static func drop(rows: inout [[HudCell]], column: Int) {
    if column < 0 || column >= rows[0].count {
      return
    }
    var row = 1
    while row < 4 {
      let cell = rows[row][column]
      if cell.kind == .blank && !HudNear.text(rows[row], column) {
        rows[row][column] = HudCell(glyph: ":", role: .mid, kind: .blank)
      }
      row += 1
    }
  }
}
