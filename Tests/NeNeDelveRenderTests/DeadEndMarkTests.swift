import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DeadEndMarkTests {
  @Test func thePlanPutsAQuestionOnTheWallAhead() {
    let world = tip()
    let grid = FramePainter.paint(world: world, clock: clock(), look: plan(), canvas: canvas())
    #expect(glyph(grid, point: CellPoint(x: 2, y: 2)) == ScreenText.runner)
    #expect(glyph(grid, point: CellPoint(x: 3, y: 2)) == ScreenText.wonder)
  }

  @Test func theDepthViewPutsOneQuestionOnThatWall() {
    let world = tip()
    let grid = FramePainter.paint(world: world, clock: clock(), look: depth(), canvas: canvas())
    #expect(count(grid, ScreenText.wonder) == 1)
  }

  private func tip() -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let back = CellPoint(x: 1, y: 2)
    let here = CellPoint(x: 2, y: 2)
    tiles[span.offset(back)] = .floor
    tiles[span.offset(here)] = .floor
    let stairs = CellPoint(x: 5, y: 1)
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: back, stairs: stairs), kind: .filledGrid)
    var seen = Array(repeating: false, count: span.count)
    seen[span.offset(back)] = true
    seen[span.offset(here)] = true
    let explorer = Explorer(position: here, path: [back, here], seen: seen)
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: explorer, rng: SplitMix64(seed: Seed(raw: 1)), steps: 2),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore)
  }

  private func plan() -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .plan, gaze: Gaze(facing: .east, place: CellPoint(x: 2, y: 2)))
  }

  private func depth() -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .depth, gaze: Gaze(facing: .east, place: CellPoint(x: 2, y: 2)))
  }

  private func canvas() -> GridSpan {
    GridSpan(width: 40, height: 5 + ScreenText.hudRows)
  }

  private func clock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 1, stageSeconds: 1),
      date: WallDate(year: 2026, month: 10, day: 25),
      time: ClockFace(hour: 12, minute: 0, second: 0),
      seed: Seed(raw: 1))
  }

  private func glyph(_ grid: CellGrid, point: CellPoint) -> Character {
    grid.cell(column: point.x, row: point.y + ScreenText.hudRows).glyph
  }

  private func count(_ grid: CellGrid, _ glyph: Character) -> Int {
    var found = 0
    var row = 0
    while row < grid.span.height {
      var column = 0
      while column < grid.span.width {
        if grid.cell(column: column, row: row).glyph == glyph {
          found += 1
        }
        column += 1
      }
      row += 1
    }
    return found
  }
}
