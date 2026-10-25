struct HudCell: Equatable {
  let glyph: Character
  let role: HudRole
  let kind: HudKind

  static let gap = HudCell(glyph: " ", role: .faint, kind: .blank)

  static func spaces(_ count: Int) -> [HudCell] {
    Array(repeating: gap, count: max(count, 0))
  }

  static func glyphs(_ text: String, role: HudRole, kind: HudKind) -> [HudCell] {
    text.map { HudCell(glyph: $0, role: role, kind: kind) }
  }
}
