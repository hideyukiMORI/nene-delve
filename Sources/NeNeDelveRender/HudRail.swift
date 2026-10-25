enum HudRail {
  static func make(_ width: Int, _ ends: [[HudCell]], _ left: [HudCell], _ right: [HudCell])
    -> [HudCell]?
  {
    if ends.count != 2 {
      return nil
    }
    let gap = width - ends[0].count - ends[1].count - left.count - right.count
    let minGap = width >= 60 ? 3 : 2
    if gap < 0 || (!left.isEmpty && !right.isEmpty && gap < minGap) {
      return nil
    }
    let row = ends[0] + left + HudCell.spaces(gap) + right + ends[1]
    if row.count != width {
      return nil
    }
    return row
  }
}
