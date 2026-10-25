import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DepthChartTests {
  @Test func aWideViewKeepsSevenCellsAndANarrowOneShrinks() {
    #expect(DepthChart.side(fitting: 80, height: 19) == 7)
    #expect(DepthChart.side(fitting: 7, height: 7) == 7)
    #expect(DepthChart.side(fitting: 5, height: 5) == 5)
    #expect(DepthChart.side(fitting: 4, height: 9) == 3)
    #expect(DepthChart.side(fitting: 2, height: 9) == 0)
  }

  @Test func aheadIsTheFacingNeighborAndRightIsClockwise() {
    let ahead = CellPoint(x: 2, y: 1)
    let right = CellPoint(x: 3, y: 2)
    #expect(mapped(ahead, facing: .north) == CellPoint(x: 4, y: 3))
    #expect(mapped(right, facing: .north) == CellPoint(x: 5, y: 4))
    #expect(mapped(ahead, facing: .east) == CellPoint(x: 5, y: 4))
    #expect(mapped(right, facing: .east) == CellPoint(x: 4, y: 5))
    #expect(mapped(ahead, facing: .south) == CellPoint(x: 4, y: 5))
    #expect(mapped(right, facing: .south) == CellPoint(x: 3, y: 4))
    #expect(mapped(ahead, facing: .west) == CellPoint(x: 3, y: 4))
    #expect(mapped(right, facing: .west) == CellPoint(x: 4, y: 3))
  }

  @Test func theDepthCornerShowsTheRunnerAndTheCellAhead() {
    let world = lane()
    let canvas = GridSpan(width: 40, height: 5 + ScreenText.hudRows)
    let depth = FramePainter.paint(world: world, clock: clock(), look: depthLook(), canvas: canvas)
    let plan = FramePainter.paint(world: world, clock: clock(), look: planLook(), canvas: canvas)
    let center = CellPoint(x: 37, y: ScreenText.hudRows + 2)
    let front = CellPoint(x: 37, y: ScreenText.hudRows + 1)
    #expect(depth.cell(column: center.x, row: center.y).glyph == ScreenText.runner)
    #expect(depth.cell(column: front.x, row: front.y).glyph == ScreenText.trail)
    #expect(depth.cell(column: center.x + 1, row: center.y).glyph == ScreenText.stairs)
    #expect(plan.cell(column: center.x, row: center.y).glyph == " ")
    #expect(plan.cell(column: front.x, row: front.y).glyph == " ")
  }

  @Test func aTallViewShowsThreeCellsAhead() {
    let world = corridor()
    let canvas = GridSpan(width: 40, height: 7 + ScreenText.hudRows)
    let depth = FramePainter.paint(
      world: world, clock: clock(), look: depthLook(), canvas: canvas)
    let plan = FramePainter.paint(
      world: world, clock: clock(), look: planLook(), canvas: canvas)
    let column = 36
    let top = ScreenText.hudRows
    #expect(depth.cell(column: column, row: top + 3).glyph == ScreenText.runner)
    #expect(depth.cell(column: column, row: top).glyph == ScreenText.trail)
    #expect(plan.cell(column: column, row: top).glyph == " ")
  }

  private func mapped(_ chart: CellPoint, facing: Direction) -> CellPoint {
    DepthChart.worldCell(chart, side: 5, origin: CellPoint(x: 4, y: 4), facing: facing)
  }

  private func corridor() -> FloorWorld {
    let span = GridSpan(width: 9, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let here = CellPoint(x: 2, y: 2)
    let ahead = CellPoint(x: 5, y: 2)
    let stairs = CellPoint(x: 6, y: 2)
    tiles[span.offset(here)] = .floor
    tiles[span.offset(CellPoint(x: 3, y: 2))] = .floor
    tiles[span.offset(CellPoint(x: 4, y: 2))] = .floor
    tiles[span.offset(ahead)] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: here, stairs: stairs), kind: .filledGrid)
    var seen = Array(repeating: false, count: span.count)
    seen[span.offset(here)] = true
    seen[span.offset(ahead)] = true
    let explorer = Explorer(position: here, path: [here], seen: seen)
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: explorer, rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore)
  }

  private func lane() -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let here = CellPoint(x: 2, y: 2)
    let east = CellPoint(x: 3, y: 2)
    let south = CellPoint(x: 2, y: 3)
    tiles[span.offset(here)] = .floor
    tiles[span.offset(east)] = .floor
    tiles[span.offset(south)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: here, stairs: south), kind: .filledGrid)
    var seen = Array(repeating: false, count: span.count)
    seen[span.offset(here)] = true
    seen[span.offset(east)] = true
    let explorer = Explorer(position: here, path: [here], seen: seen)
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: explorer, rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore)
  }

  private func depthLook() -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .depth, gaze: Gaze(facing: .east, place: CellPoint(x: 2, y: 2)))
  }

  private func planLook() -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .plan, gaze: Gaze(facing: .east, place: CellPoint(x: 2, y: 2)))
  }

  private func clock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 1, stageSeconds: 1),
      date: WallDate(year: 2026, month: 10, day: 25),
      time: ClockFace(hour: 12, minute: 0, second: 0),
      seed: Seed(raw: 1))
  }
}
