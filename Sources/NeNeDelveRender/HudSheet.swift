enum HudSheet {
  static func paint(_ brief: HudBrief, width: Int, step: Int) -> [[HudCell]] {
    if width <= 0 {
      return Array(repeating: [], count: ScreenText.hudRows)
    }
    let read = HudRead(
      brief: brief, width: width, step: step,
      omitted: HudFit.omitted(brief, width: width, step: step))
    let beat = HudBeat.phase(seed: brief.clock.seed.raw, depth: brief.floor.depth, step: step)
    let rows = HudMorph.blend(read, beat)
    if rows.count == ScreenText.hudRows && rows.allSatisfy({ $0.count == width }) {
      return rows
    }
    return Array(repeating: HudCell.spaces(width), count: ScreenText.hudRows)
  }
}
