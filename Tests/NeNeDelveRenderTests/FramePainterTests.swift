import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct FramePainterTests {
  @Test func hudShowsFloorClockSeedAndTheme() {
    let world = opened()
    let grid = FramePainter.paint(
      world: world, clock: sampleClock(), look: flat(), canvas: canvas(for: world))
    let shown = (0..<ScreenText.hudRows).map { line(grid, row: $0) }.joined()
    #expect(shown.contains("B1F"))
    #expect(shown.contains("LV"))
    #expect(shown.contains("HP"))
    #expect(shown.contains("MP"))
    #expect(shown.contains("EXP"))
    #expect(shown.contains("01:01:01"))
    #expect(shown.contains("00:00:05"))
    #expect(shown.contains("12:40:00"))
    #expect(shown.contains("(9)"))
    #expect(shown.contains("NEON GRID"))
    #expect(shown.contains("2D"))
    #expect(shown.contains(">>"))
    #expect(shown.contains("/"))
    #expect(shown.contains("="))
    #expect(!shown.contains("SEED:"))
    #expect(!shown.contains("MODE:"))
    #expect(
      grid.cell(column: 0, row: 0).background == ThemePalette.palette(.neonGrid).ink.background)
    #expect(glyph(grid, point: world.walk.explorer.position) == ScreenText.runner)
    #expect(glyph(grid, point: world.walk.maze.stairs) == ScreenText.stairs)
    #expect(grid.cell(column: 0, row: ScreenText.hudRows).glyph == ScreenText.joint)
  }

  @Test func anArmedPitShowsACaret() {
    let maze = rectangle()
    let pit = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: pit, phase: .sealed, kind: .pit),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: pit) == ScreenText.pit)
  }

  @Test func aStepLeavesATrailOnTheFloor() {
    var world = opened()
    let start = world.walk.explorer.position
    guard case .running(let next) = FloorReducer.tick(world) else {
      Issue.record("the first step stays on this floor")
      return
    }
    world = next
    let grid = FramePainter.paint(
      world: world, clock: sampleClock(), look: flat(), canvas: canvas(for: world))
    #expect(glyph(grid, point: start) == ScreenText.trail)
    #expect(glyph(grid, point: world.walk.explorer.position) == ScreenText.runner)
  }

  @Test func buriedRockStaysBlank() {
    let plan = MazeFactory.rooms(seed: Seed(raw: 1), span: GridSpan(width: 41, height: 21))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(blankRock(grid, maze: maze))
  }

  @Test func aRectangularRoomIsOneFrame() {
    let maze = rectangle()
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: CellPoint(x: 2, y: 2)) == ScreenText.joint)
    #expect(glyph(grid, point: CellPoint(x: 4, y: 2)) == ScreenText.dash)
    #expect(glyph(grid, point: CellPoint(x: 2, y: 4)) == ScreenText.bar)
    #expect(glyph(grid, point: CellPoint(x: 8, y: 2)) == ScreenText.joint)
    #expect(glyph(grid, point: CellPoint(x: 1, y: 2)) == ScreenText.floor)
    #expect(glyph(grid, point: CellPoint(x: 2, y: 1)) == ScreenText.floor)
    #expect(skinMatches(grid, maze: maze))
  }

  @Test func carvedRoomsKeepASingleSkin() {
    let plan = MazeFactory.rooms(seed: Seed(raw: 1), span: GridSpan(width: 41, height: 21))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(skinMatches(grid, maze: maze))
  }

  @Test func aSealedChestIsADollar() {
    let maze = rectangle()
    let chest = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: chest, phase: .sealed),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: chest) == ScreenText.chest)
  }

  @Test func anOpeningChestThrowsSparks() {
    let maze = rectangle()
    let chest = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: chest, phase: .bursting(1)),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: CellPoint(x: 4, y: 3)) == ScreenText.spark(1))
  }

  @Test func aLakeRipplesInsteadOfATrail() {
    let maze = rectangle()
    let water = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: water, phase: .open, kind: .lake),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: water) == ScreenText.ripple(water.x + water.y))
    #expect(
      cell(grid, point: water).background == ThemePalette.palette(.neonGrid).accent.mark.water)
  }

  @Test func theRunnerStandsInTheWater() {
    let maze = rectangle()
    let water = CellPoint(x: 4, y: 4)
    let base = furnished(maze, chest: water, phase: .open, kind: .lake)
    let standing = Explorer(
      position: water, path: [maze.ends.start, water], seen: base.walk.explorer.seen)
    let walk = FloorWalk(maze: maze, explorer: standing, rng: base.walk.rng, steps: 0)
    let world = FloorWorld(
      course: base.course, walk: walk, fixtures: base.fixtures, aim: .explore)
    let grid = FramePainter.paint(
      world: world, clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    let painted = cell(grid, point: water)
    #expect(painted.glyph == ScreenText.runner)
    #expect(painted.background == ThemePalette.palette(.neonGrid).accent.mark.water)
  }

  @Test func aProwlerBlinksAndAFightFlashes() {
    let maze = rectangle()
    let spot = CellPoint(x: 4, y: 4)
    let blinking = FloorProwler(point: spot, chases: false, mood: .blink)
    let quiet = FramePainter.paint(
      world: haunted(maze, beast: blinking, steps: 0),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    let body = cell(quiet, point: spot)
    #expect(body.glyph == ScreenText.prowler)
    #expect(body.foreground == ThemePalette.palette(.neonGrid).accent.mark.threat)
    let alarm = FramePainter.paint(
      world: haunted(maze, beast: blinking, steps: 1),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(alarm, point: spot) == ScreenText.alarm)
    let fighting = FloorProwler(point: spot, chases: true, mood: .fight(1))
    let battle = FramePainter.paint(
      world: haunted(maze, beast: fighting, steps: 1),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(battle, point: CellPoint(x: 4, y: 3)) == ScreenText.clash(1))
  }

  @Test func screenTextKeepsTheTooSmallLine() {
    #expect(ScreenText.tooSmall == "端末が小さすぎる")
    #expect(ScreenText.rejection(.unknownOption) == "不明な起動オプションです")
  }

  private func opened() -> FloorWorld {
    guard
      case .world(let world) = FloorReducer.begin(
        launchSeed: Seed(raw: 9), span: GridSpan(width: 11, height: 9))
    else {
      fatalError("the sample span fits a maze")
    }
    return world
  }

  private func canvas(for world: FloorWorld) -> GridSpan {
    canvas(forMaze: world.walk.maze)
  }

  private func canvas(forMaze maze: Maze) -> GridSpan {
    GridSpan(width: 80, height: maze.span.height + ScreenText.hudRows)
  }

  @Test func thePlanDrawsTheUpStairApartFromTheDownStair() {
    let maze = upHall()
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: CellPoint(x: 3, y: 5)) == ScreenText.ascent)
    #expect(glyph(grid, point: maze.stairs) == ScreenText.stairs)
  }

  @Test func depthShowsTheUpStairAhead() {
    let maze = upHall()
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(), look: eyed(maze), canvas: canvas(forMaze: maze))
    #expect(column(grid, at: grid.span.width / 2).contains("<"))
  }

  @Test func depthShowsTheStairsAheadInsteadOfTheMap() {
    let maze = nearHall()
    let grid = FramePainter.paint(
      world: world(maze), clock: sampleClock(),
      look: eyed(maze), canvas: canvas(forMaze: maze))
    let shown = column(grid, at: grid.span.width / 2)
    let frame = picture(grid)
    #expect(shown.contains(">"))
    #expect(!frame.contains("-"))
    #expect(!frame.contains("#"))
    #expect(!frame.contains("%"))
    #expect(!frame.contains("@"))
    #expect(!frame.contains("+"))
  }

  @Test func depthShowsAChestAndAProwlerAhead() {
    let maze = hall()
    let chest = CellPoint(x: 4, y: 5)
    let beast = FloorProwler(point: CellPoint(x: 6, y: 5), chases: false, mood: .blink)
    let grid = FramePainter.paint(
      world: stocked(maze, chest: chest, beast: beast),
      clock: sampleClock(),
      look: eyed(maze), canvas: canvas(forMaze: maze)
    )
    let shown = picture(grid)
    #expect(shown.contains("$"))
    #expect(shown.contains("&"))
  }

  @Test func thePlanDrawsABossAsB() {
    let maze = rectangle()
    let spot = CellPoint(x: 4, y: 4)
    let blinking = FloorProwler(bossAt: spot, mood: .blink, life: 40)
    let quiet = FramePainter.paint(
      world: haunted(maze, beast: blinking, steps: 0),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(quiet, point: spot) == ScreenText.boss)
    #expect(glyph(quiet, point: spot) != ScreenText.prowler)
    let alarm = FramePainter.paint(
      world: haunted(maze, beast: blinking, steps: 1),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(alarm, point: spot) == ScreenText.alarm)
    let fighting = FloorProwler(bossAt: spot, mood: .fight(1), life: 40)
    let battle = FramePainter.paint(
      world: haunted(maze, beast: fighting, steps: 1),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(battle, point: spot) == ScreenText.boss)
  }

  @Test func depthShowsABossAsB() {
    let maze = hall()
    let beast = FloorProwler(bossAt: CellPoint(x: 6, y: 5), mood: .blink, life: 40)
    let grid = FramePainter.paint(
      world: stocked(maze, chest: CellPoint(x: 4, y: 5), beast: beast),
      clock: sampleClock(),
      look: eyed(maze), canvas: canvas(forMaze: maze))
    let shown = picture(grid)
    #expect(shown.contains("B"))
    #expect(!shown.contains("&"))
  }

  @Test func aSealedWarpBlinksOnThePlan() {
    let maze = rectangle()
    let pad = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: pad, phase: .sealed, kind: .warp),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    let painted = cell(grid, point: pad)
    #expect(painted.glyph == ScreenText.via(pad.x + pad.y))
    #expect(painted.foreground == ThemePalette.palette(.neonGrid).accent.hud)
    #expect(painted.background == ThemePalette.palette(.neonGrid).ink.background)
  }

  @Test func anOpenWarpLeavesTheFloorBlank() {
    let maze = rectangle()
    let pad = CellPoint(x: 4, y: 4)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: pad, phase: .open, kind: .warp),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: pad) == ScreenText.floor)
  }

  @Test func depthShowsAWarpAhead() {
    let maze = hall()
    let pad = CellPoint(x: 4, y: 5)
    let grid = FramePainter.paint(
      world: furnished(maze, chest: pad, phase: .sealed, kind: .warp),
      clock: sampleClock(), look: eyed(maze), canvas: canvas(forMaze: maze))
    #expect(picture(grid).contains(String(ScreenText.via(pad.x + pad.y))))
  }

  @Test func aWarpPauseGlitchesTheOpenNeighbors() {
    let maze = hall()
    let runner = CellPoint(x: 3, y: 5)
    let grid = FramePainter.paint(
      world: pausedWarp(maze, at: runner, wade: FloorFixture.warpSpan, steps: 2),
      clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    let west = CellPoint(x: 2, y: 5)
    let east = CellPoint(x: 4, y: 5)
    #expect(glyph(grid, point: runner) == ScreenText.runner)
    #expect(glyph(grid, point: west) == ScreenText.glitch(2 + west.x + west.y))
    #expect(glyph(grid, point: east) == ScreenText.glitch(2 + east.x + east.y))
    #expect(cell(grid, point: east).foreground == ThemePalette.palette(.neonGrid).accent.hud)
    #expect(cell(grid, point: east).background == ThemePalette.palette(.neonGrid).ink.background)
    let shown = (0..<ScreenText.hudRows).map { line(grid, row: $0) }.joined()
    #expect(shown.contains("VIA o"))
    #expect(shown.contains("ｽﾞﾚﾀ"))
  }

  @Test func aChestSparkCoversTheWarpGlitch() {
    let maze = rectangle()
    let runner = CellPoint(x: 4, y: 4)
    let chest = CellPoint(x: 5, y: 3)
    let shared = CellPoint(x: 4, y: 3)
    let base = pausedWarp(maze, at: runner, wade: FloorFixture.warpSpan, steps: 1)
    let bursting = FloorFixture(point: chest, kind: .chest, phase: .bursting(1))
    let world = FloorWorld(
      course: base.course, walk: base.walk,
      fixtures: FloorFixtureField(fixtures: [bursting], wade: base.fixtures.wade),
      aim: base.aim)
    let grid = FramePainter.paint(
      world: world, clock: sampleClock(), look: flat(), canvas: canvas(forMaze: maze))
    #expect(glyph(grid, point: shared) == ScreenText.spark(1))
    #expect(glyph(grid, point: CellPoint(x: 3, y: 4)) == ScreenText.glitch(1 + 3 + 4))
  }

  private func pausedWarp(_ maze: Maze, at place: CellPoint, wade: Int, steps: Int) -> FloorWorld {
    let base = world(maze)
    var seen = base.walk.explorer.seen
    seen[maze.span.offset(place)] = true
    let explorer = Explorer(position: place, path: [maze.start, place], seen: seen)
    let walk = FloorWalk(maze: maze, explorer: explorer, rng: base.walk.rng, steps: steps)
    let line = DelverLine(moment: .warp, voice: 0, note: 0, left: DelverLine.span)
    let course = FloorCourse(
      launchSeed: Seed(raw: 1), floor: .first, pace: .explore,
      delver: Delver(vitals: .fresh(), line: line))
    return FloorWorld(
      course: course, walk: walk, fixtures: FloorFixtureField(fixtures: [], wade: wade),
      aim: .explore)
  }

  private func upHall() -> Maze {
    let span = GridSpan(width: 15, height: 11)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 5)
    let stairs = CellPoint(x: 1, y: 1)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(CellPoint(x: 2, y: 5))] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
    return maze.withAscent(CellPoint(x: 3, y: 5))
  }

  private func nearHall() -> Maze {
    let span = GridSpan(width: 15, height: 11)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    tiles[span.offset(CellPoint(x: 1, y: 5))] = .floor
    tiles[span.offset(CellPoint(x: 2, y: 5))] = .floor
    let stairs = CellPoint(x: 3, y: 5)
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: CellPoint(x: 1, y: 5), stairs: stairs),
      kind: .filledGrid)
  }

  private func hall() -> Maze {
    let span = GridSpan(width: 15, height: 11)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var column = 1
    while column <= 8 {
      tiles[span.offset(CellPoint(x: column, y: 5))] = .floor
      column += 1
    }
    let stairs = CellPoint(x: 9, y: 5)
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: CellPoint(x: 1, y: 5), stairs: stairs),
      kind: .filledGrid)
  }

  private func stocked(_ maze: Maze, chest: CellPoint, beast: FloorProwler) -> FloorWorld {
    let base = furnished(maze, chest: chest, phase: .sealed)
    return FloorWorld(
      course: base.course, walk: base.walk,
      fixtures: FloorFixtureField(fixtures: base.fixtures.fixtures, wade: 0, prowlers: [beast]),
      aim: base.aim)
  }

  private func column(_ grid: CellGrid, at column: Int) -> String {
    var text = ""
    var row = ScreenText.hudRows
    while row < grid.span.height {
      text.append(grid.cell(column: column, row: row).glyph)
      row += 1
    }
    return text
  }

  private func picture(_ grid: CellGrid) -> String {
    var text = ""
    var row = ScreenText.hudRows
    while row < grid.span.height {
      text += line(grid, row: row)
      row += 1
    }
    return text
  }

  private func flat() -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .plan, gaze: Gaze(facing: .north, place: CellPoint(x: 1, y: 1)))
  }

  private func eyed(_ maze: Maze) -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .depth, gaze: Gaze(facing: .east, place: maze.start))
  }

  private func world(_ maze: Maze) -> FloorWorld {
    FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore
    )
  }

  private func furnished(
    _ maze: Maze, chest: CellPoint, phase: FloorFixture.Phase, kind: FloorFixture.Kind = .chest
  ) -> FloorWorld {
    let fixture = FloorFixture(point: chest, kind: kind, phase: phase)
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: [fixture], wade: 0),
      aim: .explore
    )
  }

  private func haunted(_ maze: Maze, beast: FloorProwler, steps: Int) -> FloorWorld {
    FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)),
        steps: steps),
      fixtures: FloorFixtureField(fixtures: [], wade: 0, prowlers: [beast]),
      aim: .explore
    )
  }

  private func rectangle() -> Maze {
    let span = GridSpan(width: 11, height: 9)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var row = 3
    while row <= 6 {
      var column = 3
      while column <= 7 {
        tiles[span.offset(CellPoint(x: column, y: row))] = .floor
        column += 1
      }
      row += 1
    }
    let stairs = CellPoint(x: 5, y: 5)
    tiles[span.offset(stairs)] = .stairs
    let ends = MazeEnds(start: CellPoint(x: 3, y: 3), stairs: stairs)
    return Maze(span: span, tiles: tiles, ends: ends, kind: .rooms)
  }

  private func skinMatches(_ grid: CellGrid, maze: Maze) -> Bool {
    var row = 0
    while row < maze.span.height {
      var column = 0
      while column < maze.span.width {
        let point = CellPoint(x: column, y: row)
        if maze.tile(at: point) == .wall && !skinAgrees(grid, maze: maze, point: point) {
          return false
        }
        column += 1
      }
      row += 1
    }
    return true
  }

  private func skinAgrees(_ grid: CellGrid, maze: Maze, point: CellPoint) -> Bool {
    let mark = glyph(grid, point: point)
    if touchesSkin(maze, point) {
      return mark == ScreenText.joint || mark == ScreenText.bar || mark == ScreenText.dash
    }
    return mark == ScreenText.floor
  }

  private func touchesSkin(_ maze: Maze, _ point: CellPoint) -> Bool {
    var row = -1
    while row <= 1 {
      var column = -1
      while column <= 1 {
        let beside = column != 0 || row != 0
        let next = CellPoint(x: point.x + column, y: point.y + row)
        if beside && openTile(maze, next) {
          return true
        }
        column += 1
      }
      row += 1
    }
    return false
  }

  private func openTile(_ maze: Maze, _ point: CellPoint) -> Bool {
    if !maze.span.contains(point) {
      return false
    }
    switch maze.tile(at: point) {
    case .wall:
      return false
    case .floor, .stairs:
      return true
    }
  }

  private func blankRock(_ grid: CellGrid, maze: Maze) -> Bool {
    var row = 0
    while row < maze.span.height {
      var column = 0
      while column < maze.span.width {
        let point = CellPoint(x: column, y: row)
        if maze.tile(at: point) == .wall
          && glyph(grid, point: point) == ScreenText.floor
        {
          return true
        }
        column += 1
      }
      row += 1
    }
    return false
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
    cell(grid, point: point).glyph
  }

  private func cell(_ grid: CellGrid, point: CellPoint) -> Cell {
    grid.cell(column: point.x, row: point.y + ScreenText.hudRows)
  }
}
