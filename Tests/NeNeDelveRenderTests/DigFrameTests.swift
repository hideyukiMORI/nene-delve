import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DigFrameTests {
  @Test func theFirstPlanFrameDigsFromTheStart() {
    guard let maze = carved(.filledGrid, seed: 9), let shot = vantage(maze) else {
      Issue.record("expected a frontier")
      return
    }
    let world = standing(maze)
    let grid = paint(world, look: plan(shot.gaze, dug: 0), canvas: canvas(maze))
    #expect(glyph(grid, maze.start) == ScreenText.runner)
    let mark = glyph(grid, shot.frontier)
    #expect(mark == ScreenText.joint || mark == ScreenText.bar || mark == ScreenText.dash)
    let finished = paint(world, look: plan(shot.gaze, dug: nil), canvas: canvas(maze))
    #expect(glyph(finished, shot.frontier) == ScreenText.floor)
  }

  @Test func aRoomAlsoDigsFromTheStart() {
    guard let maze = carved(.rooms, seed: 1), let shot = vantage(maze) else {
      Issue.record("expected a frontier")
      return
    }
    let world = standing(maze)
    let grid = paint(world, look: plan(shot.gaze, dug: 0), canvas: canvas(maze))
    #expect(glyph(grid, maze.start) == ScreenText.runner)
    let mark = glyph(grid, shot.frontier)
    #expect(mark == ScreenText.joint || mark == ScreenText.bar || mark == ScreenText.dash)
  }

  @Test func theFirstDepthFrameDiffersFromTheFinishedMaze() {
    guard let maze = carved(.filledGrid, seed: 9), let shot = vantage(maze) else {
      Issue.record("expected a frontier")
      return
    }
    let world = standing(maze)
    let digging = paint(world, look: depth(shot.gaze, dug: 0), canvas: canvas(maze))
    let finished = paint(world, look: depth(shot.gaze, dug: nil), canvas: canvas(maze))
    #expect(digging != finished)
  }

  @Test func anUndugChestIsNotDrawnInDepth() {
    guard let maze = carved(.filledGrid, seed: 9), let shot = vantage(maze) else {
      Issue.record("expected a frontier")
      return
    }
    let chest = FloorFixture(point: shot.frontier, kind: .chest, phase: .sealed)
    let world = standing(maze, fixtures: [chest])
    let digging = paint(world, look: depth(shot.gaze, dug: 0), canvas: canvas(maze))
    let finished = paint(world, look: depth(shot.gaze, dug: nil), canvas: canvas(maze))
    #expect(count(digging, ScreenText.chest) == 0)
    #expect(count(finished, ScreenText.chest) > 0)
  }

  @Test func anUndugProwlerStaysBehindTheWall() {
    guard let maze = carved(.filledGrid, seed: 9), let shot = vantage(maze) else {
      Issue.record("expected a frontier")
      return
    }
    let beast = FloorProwler(point: shot.frontier, chases: false, mood: .blink)
    let world = standing(maze, prowlers: [beast])
    let grid = paint(world, look: plan(shot.gaze, dug: 0), canvas: canvas(maze))
    let mark = glyph(grid, shot.frontier)
    #expect(mark != ScreenText.prowler)
    #expect(mark != ScreenText.alarm)
  }

  @Test func diggingHidesTheQuestionMark() {
    let world = tip(logged: true)
    let span = canvas(world)
    let digging = paint(world, look: plan(east(), dug: DigReveal.frames - 1), canvas: span)
    let depthDig = paint(world, look: depth(east(), dug: DigReveal.frames - 1), canvas: span)
    #expect(glyph(digging, CellPoint(x: 3, y: 2)) != ScreenText.wonder)
    #expect(count(depthDig, ScreenText.wonder) == 0)
    let finished = paint(world, look: plan(east(), dug: nil), canvas: span)
    let depthDone = paint(world, look: depth(east(), dug: nil), canvas: span)
    #expect(glyph(finished, CellPoint(x: 3, y: 2)) == ScreenText.wonder)
    #expect(count(depthDone, ScreenText.wonder) == 1)
  }

  private struct Vantage {
    let gaze: Gaze
    let frontier: CellPoint
  }

  private func vantage(_ maze: Maze) -> Vantage? {
    let masked = DigReveal.maze(maze, frame: 0)
    var index = 0
    while index < maze.span.count {
      let point = CellPoint(x: index % maze.span.width, y: index / maze.span.width)
      if masked.tile(at: point) == .wall, maze.tile(at: point) == .floor,
        let stand = openNeighbor(masked, point), let facing = facing(from: stand, to: point)
      {
        return Vantage(gaze: Gaze(facing: facing, place: stand), frontier: point)
      }
      index += 1
    }
    return nil
  }

  private func openNeighbor(_ maze: Maze, _ point: CellPoint) -> CellPoint? {
    let neighbors = [
      CellPoint(x: point.x, y: point.y - 1),
      CellPoint(x: point.x, y: point.y + 1),
      CellPoint(x: point.x - 1, y: point.y),
      CellPoint(x: point.x + 1, y: point.y),
    ]
    for neighbor in neighbors where maze.span.contains(neighbor) {
      switch maze.tile(at: neighbor) {
      case .wall:
        continue
      case .floor, .stairs:
        return neighbor
      }
    }
    return nil
  }

  private func facing(from stand: CellPoint, to point: CellPoint) -> Direction? {
    if point.x == stand.x && point.y == stand.y - 1 {
      return .north
    }
    if point.x == stand.x && point.y == stand.y + 1 {
      return .south
    }
    if point.x == stand.x + 1 && point.y == stand.y {
      return .east
    }
    if point.x == stand.x - 1 && point.y == stand.y {
      return .west
    }
    return nil
  }

  private func carved(_ kind: MazeKind, seed: UInt64) -> Maze? {
    let plan = MazeFactory.make(
      kind: kind, seed: Seed(raw: seed), span: GridSpan(width: 21, height: 15))
    guard case .maze(let maze) = plan else {
      return nil
    }
    return maze
  }

  private func standing(
    _ maze: Maze, fixtures: [FloorFixture] = [], prowlers: [FloorProwler] = []
  ) -> FloorWorld {
    FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 9), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 9)), steps: 0),
      fixtures: FloorFixtureField(fixtures: fixtures, wade: 0, prowlers: prowlers),
      aim: .explore)
  }

  private func tip(logged: Bool) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let back = CellPoint(x: 1, y: 2)
    let here = CellPoint(x: 2, y: 2)
    tiles[span.offset(back)] = .floor
    tiles[span.offset(here)] = .floor
    let stairs = CellPoint(x: 5, y: 1)
    tiles[span.offset(stairs)] = .stairs
    let ends = MazeEnds(start: back, stairs: stairs)
    let dug = logged ? [back, here] : []
    let maze = Maze(span: span, tiles: tiles, plate: MazePlate(ends: ends, dug: dug), kind: .filledGrid)
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

  private func plan(_ gaze: Gaze, dug: Int?) -> FrameLook {
    FrameLook(theme: .neonGrid, view: .plan, gaze: gaze, dug: dug)
  }

  private func depth(_ gaze: Gaze, dug: Int?) -> FrameLook {
    FrameLook(theme: .neonGrid, view: .depth, gaze: gaze, dug: dug)
  }

  private func east() -> Gaze {
    Gaze(facing: .east, place: CellPoint(x: 2, y: 2))
  }

  private func canvas(_ maze: Maze) -> GridSpan {
    GridSpan(width: max(maze.span.width, 40), height: maze.span.height + ScreenText.hudRows)
  }

  private func canvas(_ world: FloorWorld) -> GridSpan {
    canvas(world.walk.maze)
  }

  private func paint(_ world: FloorWorld, look: FrameLook, canvas: GridSpan) -> CellGrid {
    FramePainter.paint(world: world, clock: clock(), look: look, canvas: canvas)
  }

  private func clock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 1, stageSeconds: 1),
      date: WallDate(year: 2026, month: 10, day: 25),
      time: ClockFace(hour: 12, minute: 0, second: 0),
      seed: Seed(raw: 1))
  }

  private func glyph(_ grid: CellGrid, _ point: CellPoint) -> Character {
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
