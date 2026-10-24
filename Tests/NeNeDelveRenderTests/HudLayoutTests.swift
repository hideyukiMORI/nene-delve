import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct HudLayoutTests {
  @Test func wideLineKeepsEveryDigitOfAHugeSeed() {
    let layout = HudLayout.make(clock: clock(UInt64.max), floor: .first, look: look(), width: 80)
    let shown = layout.first + " " + layout.second
    #expect(layout.first.count == 80)
    #expect(layout.first.hasSuffix("2D"))
    #expect(layout.second.hasSuffix("NEON GRID"))
    #expect(shown.contains("B1F"))
    #expect(shown.contains("01:01:01"))
    #expect(shown.contains("00:00:05"))
    #expect(shown.contains("2026-10-24 12:40:00"))
    #expect(shown.contains("(18446744073709551615)"))
    #expect(!shown.contains("//FLR:"))
    #expect(!shown.contains("SEED:"))
    #expect(!shown.contains("SYS:"))
    #expect(!shown.contains("MODE:"))
  }

  @Test func phosphorPutsItsNameOnTheWideLine() {
    let layout = HudLayout.make(clock: clock(1), floor: .first, look: look(.phosphor), width: 80)
    let shown = layout.first + " " + layout.second
    #expect(shown.contains("PHOSPHOR"))
    #expect(!shown.contains("NEON GRID"))
  }

  @Test func narrowLineDropsLabelsBeforeItDropsDigits() {
    let layout = HudLayout.make(
      clock: clock(UInt64.max), floor: .first, look: look(), width: 40)
    let shown = layout.first + "\n" + layout.second
    #expect(shown.contains("(18446744073709551615)"))
    #expect(shown.contains("B1F"))
    #expect(shown.contains("NEON GRID"))
    #expect(!shown.contains("2026-10-24"))
    #expect(!shown.contains("1844674407370955161)"))
    #expect(!shown.contains("1844674407370955161\n"))
    for line in [layout.first, layout.second] {
      #expect(line.count <= 40)
    }
  }

  @Test func depthPutsItsModeOnTheWideLine() {
    let layout = HudLayout.make(
      clock: clock(1), floor: .first, look: look(.neonGrid, view: .depth), width: 80)
    let shown = layout.first + " " + layout.second
    #expect(layout.first.hasSuffix("3D"))
    #expect(!shown.contains("2D"))
  }

  private func look(_ theme: ThemeName = .neonGrid, view: ViewMode = .plan) -> FrameLook {
    FrameLook(theme: theme, view: view, facing: .north)
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
