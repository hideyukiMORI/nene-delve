struct HudBand: Equatable {
  let upper: [HudCell]
  let lower: [HudCell]
  let graph: Int

  static func make(width: Int, caps: [[HudCell]], left: [[HudCell]], right: [[HudCell]]) -> HudBand?
  {
    if caps.count != 4 || left.count != 2 || right.count != 2 {
      return nil
    }
    let gap = width - caps[0].count - caps[1].count - left[0].count - right[0].count
    let minGap = width >= 60 ? 3 : 2
    if gap < 0 || (!left[0].isEmpty && !right[0].isEmpty && gap < minGap) {
      return nil
    }
    let graph = graphStart(
      width: width, gap: gap, minGap: minGap, lead: caps[0].count + left[0].count)
    let upperGap = gapCells(gap, graphLead: graph - caps[0].count - left[0].count, count: 11)
    let lowerGap = upperGap
    let upper = caps[0] + left[0] + upperGap + right[0] + caps[1]
    let lower = caps[2] + left[1] + lowerGap + right[1] + caps[3]
    if upper.count != width || lower.count != width {
      return nil
    }
    return HudBand(upper: upper, lower: lower, graph: graph)
  }

  private static func graphStart(width: Int, gap: Int, minGap: Int, lead: Int) -> Int {
    let count = 11
    if width < 60 || gap < count + 2 * minGap {
      return -1
    }
    return lead + (gap - count) / 2
  }

  private static func gapCells(_ gap: Int, graphLead: Int, count: Int) -> [HudCell] {
    var cells = HudCell.spaces(gap)
    if graphLead < 0 {
      return cells
    }
    let spark = HudCell(glyph: " ", role: .faint, kind: .spark)
    var index = 0
    while index < count && graphLead + index < cells.count {
      cells[graphLead + index] = spark
      index += 1
    }
    return cells
  }
}
