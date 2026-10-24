import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct FramePainterTests {
  @Test func hudShowsFloorClockSeedAndTheme() {
    let world = opened()
    let grid = FramePainter.paint(world: world, clock: sampleClock(), theme: .neonGrid, canvas: canvas(for: world))
    let top = line(grid, row: 0)
    let theme = line(grid, row: 1)
    #expect(top.contains("B1F"))
    #expect(top.contains("total 01:01:01"))
    #expect(top.contains("stage 00:00:05"))
    #expect(top.contains("2026-10-24 12:40:00"))
    #expect(top.contains("seed 9"))
    #expect(theme.contains("NEON GRID"))
    #expect(glyph(grid, point: world.walk.explorer.position) == ScreenText.runner)
    #expect(glyph(grid, point: world.walk.maze.stairs) == ScreenText.stairs)
  }

  @Test func screenTextKeepsTheTooSmallLine() {
    #expect(ScreenText.tooSmall == "端末が小さすぎる")
    #expect(ScreenText.rejection(.unknownOption) == "不明な起動オプションです")
  }

  private func opened() -> FloorWorld {
    guard case .world(let world) = FloorReducer.begin(launchSeed: Seed(raw: 9), span: GridSpan(width: 11, height: 9))
    else {
      fatalError("the sample span fits a maze")
    }
    return world
  }

  private func canvas(for world: FloorWorld) -> GridSpan {
    GridSpan(width: 80, height: world.walk.maze.span.height + ScreenText.hudRows)
  }

  private func sampleClock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 3661, stageSeconds: 5),
      date: WallDate(year: 2026, month: 10, day: 24),
      time: ClockFace(hour: 12, minute: 40, second: 0),
      seed: Seed(raw: 9)
    )
  }

  private func line(_ grid: CellGrid, row: Int) -> String {
    var text = ""
    var column = 0
    while column < grid.span.width {
      text.append(grid.cell(column: column, row: row).glyph)
      column += 1
    }
    return text
  }

  private func glyph(_ grid: CellGrid, point: CellPoint) -> Character {
    grid.cell(column: point.x, row: point.y + ScreenText.hudRows).glyph
  }
}
