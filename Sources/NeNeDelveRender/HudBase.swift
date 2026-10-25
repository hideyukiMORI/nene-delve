enum HudBase {
  static func plate(_ read: HudRead, aim: Bool) -> HudDraft? {
    guard let head = head(read, aim: aim), let band = band(read, aim: aim), let foot = foot(read)
    else {
      return nil
    }
    return HudDraft(
      rows: [HudCell.spaces(read.width), head, band.upper, band.lower, foot], graph: band.graph)
  }

  private static func head(_ read: HudRead, aim: Bool) -> [HudCell]? {
    let left = HudJoin.pieces(
      [
        HudWords.piece(read, .floor), HudWords.piece(read, .facing), HudWords.piece(read, .view),
        HudWords.piece(read, .level),
      ], gap: 2)
    let right = HudJoin.pieces(
      [HudWords.piece(read, .place), times(read), HudWords.piece(read, .clock)], gap: 3)
    return HudRail.make(
      read.width, [cap(read, aim: aim, tail: false), cap(read, aim: aim, tail: true)], left, right)
  }

  private static func times(_ read: HudRead) -> [HudCell] {
    let elapsed = HudWords.piece(read, .elapsed)
    let stage = HudWords.piece(read, .stage)
    if elapsed.isEmpty || stage.isEmpty {
      return elapsed + stage
    }
    return elapsed + HudCell.glyphs(" / ", role: .soft, kind: .text) + stage
  }

  private static func band(_ read: HudRead, aim: Bool) -> HudBand? {
    let theme = HudWords.piece(read, .theme)
    return HudBand.make(
      width: read.width,
      caps: [
        side(read, aim: aim, tail: false), side(read, aim: aim, tail: true),
        cap(read, aim: aim, tail: false), cap(read, aim: aim, tail: true),
      ],
      left: HudGauges.chosen(read, aim: aim),
      right: [theme, HudCell.spaces(theme.count)])
  }

  private static func foot(_ read: HudRead) -> [HudCell]? {
    let message = HudWords.piece(read, .message)
    let seed = HudWords.piece(read, .seed)
    let date = HudWords.piece(read, .date)
    let end = HudCell.glyphs(" ", role: .soft, kind: .frame)
    if message.isEmpty {
      return HudRail.make(read.width, [end, end], seed, date)
    }
    return HudRail.make(read.width, [end, end], message, seed)
  }

  private static func cap(_ read: HudRead, aim: Bool, tail: Bool) -> [HudCell] {
    let text = read.width >= 60 ? (tail ? " -+" : "+- ") : "+"
    return frame(text, aim: aim)
  }

  private static func side(_ read: HudRead, aim: Bool, tail: Bool) -> [HudCell] {
    let text = read.width >= 60 ? (tail ? "  |" : "|  ") : "|"
    return frame(text, aim: aim)
  }

  private static func frame(_ text: String, aim: Bool) -> [HudCell] {
    let shown = aim ? text : String(repeating: " ", count: text.count)
    return HudCell.glyphs(shown, role: .soft, kind: .frame)
  }
}
