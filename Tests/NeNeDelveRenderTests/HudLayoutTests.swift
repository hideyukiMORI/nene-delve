import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct HudLayoutTests {
  @Test func wideLineKeepsEveryDigitOfAHugeSeed() {
    let layout = layout(UInt64.max, width: 80, step: 0)
    let shown = shown(layout)
    #expect(layout.rows.count == 5)
    for row in layout.rows {
      #expect(row.count == 80)
    }
    #expect(shown.contains("B1F"))
    #expect(shown.contains("N"))
    #expect(shown.contains("2D"))
    #expect(shown.contains("LV01"))
    #expect(shown.contains("X003 Y007"))
    #expect(shown.contains("01:01:01"))
    #expect(shown.contains("00:00:05"))
    #expect(shown.contains("12:40:00"))
    #expect(shown.contains("HP"))
    #expect(shown.contains("MP"))
    #expect(shown.contains("EXP"))
    #expect(shown.contains("NEON GRID"))
    #expect(layout.rows[4].contains("(18446744073709551615)"))
    #expect(layout.rows[4].contains("2026-10-24 12:40:00"))
    #expect(!shown.contains("//FLR:"))
    #expect(!shown.contains("SEED:"))
    #expect(!shown.contains("1844674407370955161)"))
  }

  @Test func phosphorPutsItsNameOnTheWideLine() {
    let layout = layout(1, theme: .phosphor, width: 80, step: 0)
    let shown = shown(layout)
    #expect(shown.contains("PHOSPHOR"))
    #expect(!shown.contains("NEON GRID"))
  }

  @Test func narrowLineDropsLabelsBeforeItDropsDigits() {
    let layout = layout(UInt64.max, width: 40, step: 0)
    let shown = shown(layout)
    #expect(layout.rows.count == 5)
    for row in layout.rows {
      #expect(row.count == 40)
    }
    #expect(shown.contains("(18446744073709551615)"))
    #expect(shown.contains("B1F"))
    #expect(shown.contains("LV01"))
    #expect(shown.contains("X003"))
    #expect(shown.contains("HP"))
    #expect(shown.contains("NEON GRID"))
    #expect(!shown.contains("2026-10-24"))
    #expect(!shown.contains("1844674407370955161)"))
    #expect(!shown.contains("1844674407370955161\n"))
  }

  @Test func depthPutsItsModeOnTheWideLine() {
    let layout = layout(1, view: .depth, width: 80, step: 0)
    #expect(shown(layout).contains("3D"))
    #expect(!shown(layout).contains("2D"))
  }

  @Test func aTrapLineSitsBesideTheWholeSeed() {
    let pin = DelverLine.QuipPin(seed: Seed(raw: 9), floor: .first, place: CellPoint(x: 3, y: 7))
    let delver = Delver(vitals: .fresh(), line: DelverLine.say(.pit, pin: pin, note: 3))
    let layout = layout(9, width: 80, step: 0, delver: delver)
    #expect(layout.rows[4].contains(">>"))
    #expect(layout.rows[4].contains("TRAP"))
    #expect(layout.rows[4].contains("HP-3"))
    #expect(layout.rows[4].contains("(9)"))
    #expect(shown(layout).contains("B1F"))
    #expect(!layout.rows[4].contains("2026-10-24"))
  }

  @Test func theFooterStaysWhileThePictureChanges() {
    let aim = layout(9, width: 80, step: step(9, depth: 1, matching: { beat in
      if case .aim = beat { return true }
      return false
    }))
    let rain = layout(9, width: 80, step: step(9, depth: 1, matching: { beat in
      if case .rain = beat { return true }
      return false
    }))
    #expect(aim.rows[4] == rain.rows[4])
    #expect(aim.rows[0] != rain.rows[0])
    #expect(rain.rows[0].contains(where: { $0.isLetter }))
    #expect(tokens(aim) == tokens(rain))
  }

  private func layout(
    _ raw: UInt64, theme: ThemeName = .neonGrid, view: ViewMode = .plan, width: Int, step: Int,
    delver: Delver = .quiet
  ) -> HudLayout {
    HudLayout.make(brief(raw, theme: theme, view: view, delver: delver), width: width, step: step)
  }

  private func shown(_ layout: HudLayout) -> String {
    layout.rows.joined(separator: "\n")
  }

  private func tokens(_ layout: HudLayout) -> String {
    layout.cells.map { row in
      row.map { $0.kind == .text ? $0.glyph : "_" }.map(String.init).joined()
    }.joined(separator: "\n")
  }

  private func step(_ raw: UInt64, depth: Int, matching: (HudBeat) -> Bool) -> Int {
    var cursor = 0
    while cursor < 400 {
      if matching(HudBeat.phase(seed: raw, depth: depth, step: cursor)) {
        return cursor
      }
      cursor += 1
    }
    return 0
  }

  private func brief(
    _ raw: UInt64, theme: ThemeName, view: ViewMode, delver: Delver
  ) -> HudBrief {
    HudBrief(clock: clock(raw), floor: .first, look: look(theme, view: view), delver: delver)
  }

  private func look(_ theme: ThemeName = .neonGrid, view: ViewMode = .plan) -> FrameLook {
    FrameLook(
      theme: theme, view: view, gaze: Gaze(facing: .north, place: CellPoint(x: 3, y: 7)))
  }

  private func clock(_ raw: UInt64) -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 3661, stageSeconds: 5),
      date: WallDate(year: 2026, month: 10, day: 24),
      time: ClockFace(hour: 12, minute: 40, second: 0),
      seed: Seed(raw: raw)
    )
  }
}
