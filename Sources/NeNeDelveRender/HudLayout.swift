import NeNeDelveCore

/// HUD の 5 行。欄は入るか、丸ごと落とす。桁の途中では切らない。
public struct HudLayout: Equatable, Sendable {
  public let rows: [String]
  let cells: [[HudCell]]

  public static func make(_ brief: HudBrief, width: Int, step: Int) -> HudLayout {
    let cells = HudSheet.paint(brief, width: width, step: step)
    return HudLayout(rows: cells.map { String($0.map(\.glyph)) }, cells: cells)
  }
}
