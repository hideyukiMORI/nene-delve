enum HudAim {
  static func overlay(_ draft: HudDraft, _ read: HudRead, scan: Bool) -> [[HudCell]] {
    var rows = draft.rows
    ruler(&rows)
    if scan {
      HudScan.lay(&rows, column: HudScan.sweep(read.width, step: read.step), through: false)
    }
    let clock = (read.brief.delver.vitals.hitMax, read.step, true)
    HudGraph.draw(&rows, draft.graph, HudSamples.values(read), clock)
    return rows
  }

  private static func ruler(_ rows: inout [[HudCell]]) {
    let digits = Array("0123456789")
    var column = 0
    while column < rows[0].count {
      if column.isMultiple(of: 10) {
        rows[0][column] = HudCell(glyph: digits[column / 10 % 10], role: .soft, kind: .blank)
      } else if column.isMultiple(of: 2) {
        rows[0][column] = HudCell(glyph: ".", role: .faint, kind: .blank)
      }
      column += 1
    }
  }
}
