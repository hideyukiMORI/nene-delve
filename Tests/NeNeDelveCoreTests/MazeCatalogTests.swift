import Testing

@testable import NeNeDelveCore

struct MazeCatalogTests {
  @Test func sameSeedRepeats() {
    let span = GridSpan(width: 15, height: 9)
    for kind in MazeKind.order {
      let first = MazeFactory.make(kind: kind, seed: Seed(raw: 7), span: span)
      let second = MazeFactory.make(kind: kind, seed: Seed(raw: 7), span: span)
      #expect(first == second)
    }
  }

  @Test func rejectsTinySpan() {
    for kind in MazeKind.order {
      let plan = MazeFactory.make(
        kind: kind, seed: Seed(raw: 1), span: GridSpan(width: 4, height: 9))
      #expect(plan == .tooSmall)
    }
  }

  @Test func everyKindReachesTheStairs() {
    for kind in MazeKind.order {
      for raw in [1, 2, 9, 40] {
        for span in spans() {
          guard
            case .maze(let maze) = MazeFactory.make(
              kind: kind, seed: Seed(raw: UInt64(raw)), span: span)
          else {
            Issue.record("expected \(kind)")
            return
          }
          #expect(maze.kind == kind)
          #expect(covers(maze))
        }
      }
    }
  }

  @Test func directRoomsAndCorridorsStayPlain() {
    let span = GridSpan(width: 41, height: 21)
    for raw in [1, 9, 40] {
      expectPlain(.rooms, raw: raw, span: span, plain: MazeFactory.rooms)
      expectPlain(.filledGrid, raw: raw, span: span, plain: MazeFactory.filled)
    }
  }

  @Test func shadeCoversSomeFloorsOnly() {
    let span = GridSpan(width: 21, height: 15)
    var dark = 0
    var lit = 0
    var raw = 0
    while raw < 40 {
      let seed = Seed(raw: UInt64(raw))
      guard case .maze(let maze) = MazeFactory.make(kind: .rooms, seed: seed, span: span),
        case .maze(let plain) = MazeFactory.rooms(seed: seed, span: span)
      else {
        Issue.record("expected rooms")
        return
      }
      #expect(maze.tiles == plain.tiles)
      #expect(maze.kind == .rooms)
      #expect(!plain.veil.shade)
      if maze.veil.shade {
        dark += 1
        #expect(DigReveal.maze(maze, frame: 0).veil.shade)
        #expect(DigReveal.maze(maze, frame: DigReveal.frames - 1) == maze)
        #expect(maze.opening([maze.start]).veil.shade)
        #expect(maze.withAscent(maze.start).veil.shade)
      } else {
        lit += 1
      }
      raw += 1
    }
    #expect(dark > 0)
    #expect(lit > 0)
  }

  @Test func loopsOpenMoreThanAPerfectMaze() {
    let span = GridSpan(width: 41, height: 21)
    for raw in [1, 2, 9, 40] {
      guard case .maze(let maze) = made(.loops, raw: raw, span: span) else {
        Issue.record("expected loops")
        return
      }
      #expect(openCount(maze) > perfect(span))
    }
  }

  @Test func aCavernKeepsWallsAndOpensWider() {
    let span = GridSpan(width: 41, height: 21)
    for raw in [1, 2, 9, 40] {
      guard case .maze(let maze) = made(.cavern, raw: raw, span: span) else {
        Issue.record("expected a cavern")
        return
      }
      #expect(openCount(maze) > perfect(span))
      #expect(interiorWalls(maze) > 0)
    }
  }

  @Test func aSpiralNeverBranches() {
    for span in spans() {
      guard case .maze(let maze) = made(.spiral, raw: 1, span: span) else {
        Issue.record("expected a spiral")
        return
      }
      #expect(degree(maze) <= 2)
      #expect(covers(maze))
    }
  }

  @Test func blocksAreMoreClosedThanCircuits() {
    let span = GridSpan(width: 41, height: 21)
    for raw in [1, 2, 9, 40] {
      guard case .maze(let blocks) = made(.blocks, raw: raw, span: span),
        case .maze(let circuit) = made(.circuit, raw: raw, span: span)
      else {
        Issue.record("expected both mazes")
        return
      }
      #expect(openCount(blocks) < openCount(circuit))
      #expect(interiorWalls(circuit) > 0)
    }
  }

  @Test func pillarsIslandsAndRacksKeepWalls() {
    let wide = GridSpan(width: 41, height: 21)
    guard case .maze(let pillars) = made(.pillars, raw: 1, span: GridSpan(width: 5, height: 5)),
      case .maze(let islands) = made(.islands, raw: 1, span: wide),
      case .maze(let racks) = made(.racks, raw: 1, span: wide)
    else {
      Issue.record("expected the geometries")
      return
    }
    #expect(interiorWalls(pillars) > 0)
    #expect(interiorWalls(islands) > 0)
    #expect(interiorWalls(racks) > 0)
  }

  @Test func shiftingOpensOneWallOnThePeriod() {
    let span = GridSpan(width: 15, height: 9)
    guard let maze = shifting(span) else {
      Issue.record("expected two movable walls")
      return
    }
    let base = openCount(maze)
    let once = maze.cycled(keeping: [])
    let twice = once.cycled(keeping: [])
    #expect(ShiftWall.period == 24)
    #expect(openCount(once) == base + 1)
    #expect(openCount(twice) == base + 1)
    #expect(reaches(once))
    #expect(reaches(twice))
    let cap = maze.veil.shifts[0]
    #expect(once.cycled(keeping: [cap]).tile(at: cap) == .floor)
    #expect(openCount(ShiftWall.turn(paced(maze, steps: 24)).walk.maze) == base + 1)
    #expect(ShiftWall.turn(paced(maze, steps: 23)).walk.maze == maze)
    #expect(ShiftWall.turn(paced(maze, steps: 0)).walk.maze == maze)
    guard case .maze(let rooms) = MazeFactory.rooms(seed: Seed(raw: 1), span: span) else {
      Issue.record("expected rooms")
      return
    }
    #expect(ShiftWall.turn(paced(rooms, steps: 24)).walk.maze == rooms)
  }

  @Test func aLanternDoesNotChangeTheWalkedMaze() {
    let maze = lane().veiled(MazeVeil(shade: true, shifts: [], phase: 0))
    let world = paced(maze, steps: 0)
    let far = CellPoint(x: 6, y: 1)
    let near = CellPoint(x: 2, y: 1)
    let masked = DarkFloor.masked(world)
    #expect(DarkFloor.radius == 4)
    #expect(world.walk.maze.tile(at: far) == .floor)
    #expect(masked.walk.maze.tile(at: far) == .wall)
    #expect(masked.walk.maze.tile(at: near) == .floor)
    let plain = paced(lane(), steps: 0)
    #expect(DarkFloor.masked(plain).walk.maze == plain.walk.maze)
  }

  private func expectPlain(
    _ kind: MazeKind, raw: Int, span: GridSpan,
    plain: (Seed, GridSpan) -> MazePlan
  ) {
    let seed = Seed(raw: UInt64(raw))
    guard case .maze(let direct) = plain(seed, span),
      case .maze(let made) = MazeFactory.make(kind: kind, seed: seed, span: span)
    else {
      Issue.record("expected \(kind)")
      return
    }
    #expect(direct.tiles == made.tiles)
    #expect(direct.kind == kind)
    #expect(!direct.veil.shade)
  }

  private func made(_ kind: MazeKind, raw: Int, span: GridSpan) -> MazePlan {
    MazeFactory.make(kind: kind, seed: Seed(raw: UInt64(raw)), span: span)
  }

  private func spans() -> [GridSpan] {
    [
      GridSpan(width: 5, height: 5),
      GridSpan(width: 15, height: 9),
      GridSpan(width: 41, height: 21),
    ]
  }

  private func shifting(_ span: GridSpan) -> Maze? {
    var raw = 1
    while raw <= 80 {
      if case .maze(let maze) = made(.shifting, raw: raw, span: span), maze.veil.shifts.count >= 2 {
        return maze
      }
      raw += 1
    }
    return nil
  }

  private func paced(_ maze: Maze, steps: Int) -> FloorWorld {
    FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)),
        steps: steps),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore)
  }

  private func lane() -> Maze {
    let span = GridSpan(width: 15, height: 9)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var x = 1
    while x <= 12 {
      tiles[span.offset(CellPoint(x: x, y: 1))] = .floor
      x += 1
    }
    let stairs = CellPoint(x: 12, y: 1)
    tiles[span.offset(stairs)] = .stairs
    let ends = MazeEnds(start: CellPoint(x: 1, y: 1), stairs: stairs)
    return Maze(span: span, tiles: tiles, ends: ends, kind: .filledGrid)
  }

  private func perfect(_ span: GridSpan) -> Int {
    let rooms = ((span.width - 1) / 2) * ((span.height - 1) / 2)
    return rooms * 2 - 1
  }

  private func openCount(_ maze: Maze) -> Int {
    maze.tiles.filter { tile in
      switch tile {
      case .floor, .stairs:
        true
      case .wall:
        false
      }
    }.count
  }

  private func interiorWalls(_ maze: Maze) -> Int {
    var count = 0
    var y = 1
    while y < maze.span.height - 1 {
      count += wallRow(maze, y: y)
      y += 1
    }
    return count
  }

  private func wallRow(_ maze: Maze, y: Int) -> Int {
    var count = 0
    var x = 1
    while x < maze.span.width - 1 {
      if maze.tile(at: CellPoint(x: x, y: y)) == .wall {
        count += 1
      }
      x += 1
    }
    return count
  }

  private func degree(_ maze: Maze) -> Int {
    var worst = 0
    var index = 0
    while index < maze.tiles.count {
      if maze.tiles[index] != .wall {
        let point = CellPoint(x: index % maze.span.width, y: index / maze.span.width)
        worst = max(worst, exits(maze, at: point))
      }
      index += 1
    }
    return worst
  }

  private func exits(_ maze: Maze, at point: CellPoint) -> Int {
    var count = 0
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      if maze.span.contains(next) && maze.tile(at: next) != .wall {
        count += 1
      }
    }
    return count
  }

  private func covers(_ maze: Maze) -> Bool {
    if maze.start == maze.stairs || maze.tile(at: maze.start) != .floor {
      return false
    }
    if maze.tile(at: maze.stairs) != .stairs || !reaches(maze) || !logged(maze) {
      return false
    }
    let seen = flooded(maze)
    var index = 0
    while index < maze.tiles.count {
      let open = maze.tiles[index] != .wall
      if open != seen[index] {
        return false
      }
      index += 1
    }
    return true
  }

  private func reaches(_ maze: Maze) -> Bool {
    flooded(maze)[maze.span.offset(maze.stairs)]
  }

  private func flooded(_ maze: Maze) -> [Bool] {
    var seen = Array(repeating: false, count: maze.span.count)
    var queue = [maze.start]
    seen[maze.span.offset(maze.start)] = true
    var cursor = 0
    while cursor < queue.count {
      visit(maze, from: queue[cursor], queue: &queue, seen: &seen)
      cursor += 1
    }
    return seen
  }

  private func visit(
    _ maze: Maze, from point: CellPoint, queue: inout [CellPoint], seen: inout [Bool]
  ) {
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      if !maze.span.contains(next) || seen[maze.span.offset(next)] || maze.tile(at: next) == .wall {
        continue
      }
      seen[maze.span.offset(next)] = true
      queue.append(next)
    }
  }

  private func logged(_ maze: Maze) -> Bool {
    var marked = Array(repeating: false, count: maze.span.count)
    for point in maze.dug {
      if !maze.span.contains(point) || marked[maze.span.offset(point)] {
        return false
      }
      marked[maze.span.offset(point)] = true
    }
    var index = 0
    while index < maze.tiles.count {
      let open = maze.tiles[index] != .wall
      if open != marked[index] {
        return false
      }
      index += 1
    }
    return true
  }
}
