import Testing

@testable import NeNeDelveCore

struct WarpPadTests {
  @Test func someWideFloorsPlaceOneWarpPair() {
    let span = GridSpan(width: 41, height: 21)
    var withPads = 0
    var without = 0
    for raw in 1...36 {
      guard let world = opened(UInt64(raw), span: span) else {
        Issue.record("expected a world")
        return
      }
      let pads = warpPoints(world)
      if pads.isEmpty {
        without += 1
        continue
      }
      withPads += 1
      #expect(pads.count == 2)
      if pads.count == 2 {
        #expect(pads[0] != pads[1])
        #expect(farPair(pads, world: world))
      }
      for pad in pads {
        #expect(world.walk.maze.tile(at: pad) == .floor)
        #expect(pad != world.walk.maze.start)
        #expect(pad != world.walk.maze.stairs)
        #expect(pad != world.walk.maze.ends.ascent)
        #expect(world.fixtures.warp(at: pad))
        for beast in world.fixtures.prowlers {
          #expect(beast.point != pad)
        }
      }
    }
    #expect(withPads > 0)
    #expect(without > 0)
  }

  @Test func theSameSeedPlacesTheSameWarp() {
    let span = GridSpan(width: 41, height: 21)
    let first = opened(1, span: span)
    let second = opened(1, span: span)
    #expect(warpPoints(first) == warpPoints(second))
    #expect(first?.fixtures.prowlers == second?.fixtures.prowlers)
    var differed = false
    for raw in 2...12 {
      if warpPoints(opened(UInt64(raw), span: span)) != warpPoints(first) {
        differed = true
      }
    }
    #expect(differed)
  }

  @Test func aSealedWarpDoesNotHoldTheStairs() {
    let pad = FloorFixture(point: CellPoint(x: 2, y: 2), kind: .warp, phase: .sealed)
    let field = FloorFixtureField(fixtures: [pad], wade: 0)
    #expect(!field.holdsSealed)
    let pit = FloorFixture(point: CellPoint(x: 3, y: 2), kind: .pit, phase: .sealed)
    #expect(FloorFixtureField(fixtures: [pit], wade: 0).holdsSealed)
  }

  @Test func steppingOnAPadJumpsOnceAndPauses() {
    let world = lane()
    let near = CellPoint(x: 2, y: 2)
    let far = CellPoint(x: 5, y: 2)
    let vitals = world.course.delver.vitals
    #expect(world.fixtures.exit(from: near) == far)
    guard case .running(let jumped) = FloorReducer.tick(world) else {
      Issue.record("the pad did not stay on this floor")
      return
    }
    #expect(jumped.walk.explorer.position == far)
    #expect(jumped.course.floor.depth == world.course.floor.depth)
    #expect(jumped.course.delver.vitals == vitals)
    #expect(jumped.course.delver.line.moment == .warp)
    #expect(jumped.course.delver.line.note == 0)
    #expect(jumped.fixtures.wade == FloorFixture.warpSpan)
    #expect(phase(jumped, near) == .open)
    #expect(phase(jumped, far) == .open)
    #expect(jumped.fixtures.exit(from: far) == nil)
    guard case .running(let paused) = FloorReducer.tick(jumped) else {
      Issue.record("the landing did not pause")
      return
    }
    #expect(paused.walk.explorer.position == far)
    #expect(paused.fixtures.wade == FloorFixture.warpSpan - 1)
    #expect(paused.course.floor.depth == world.course.floor.depth)
  }

  private func opened(_ raw: UInt64, span: GridSpan) -> FloorWorld? {
    guard case .world(let world) = FloorReducer.begin(launchSeed: Seed(raw: raw), span: span) else {
      return nil
    }
    return world
  }

  private func warpPoints(_ world: FloorWorld?) -> [CellPoint] {
    guard let world else {
      return []
    }
    var points: [CellPoint] = []
    for fixture in world.fixtures.fixtures {
      switch fixture.kind {
      case .warp:
        points.append(fixture.point)
        #expect(fixture.phase == .sealed)
      case .chest, .lake, .pit:
        break
      }
    }
    return points
  }

  private func farPair(_ pads: [CellPoint], world: FloorWorld) -> Bool {
    let open = openSpots(world)
    return partner(pads[1], of: pads[0], open: open) || partner(pads[0], of: pads[1], open: open)
  }

  private func partner(_ other: CellPoint, of origin: CellPoint, open: [CellPoint]) -> Bool {
    var chosen: CellPoint?
    var best = -1
    for spot in open where spot != origin {
      let distance = abs(spot.x - origin.x) + abs(spot.y - origin.y)
      if distance > best {
        chosen = spot
        best = distance
      }
    }
    return chosen == other
  }

  private func openSpots(_ world: FloorWorld) -> [CellPoint] {
    var taken: [CellPoint] = []
    for fixture in world.fixtures.fixtures {
      switch fixture.kind {
      case .warp:
        break
      case .chest, .lake, .pit:
        taken.append(fixture.point)
      }
    }
    for beast in world.fixtures.prowlers {
      taken.append(beast.point)
    }
    var spots: [CellPoint] = []
    var row = 0
    let maze = world.walk.maze
    while row < maze.span.height {
      var column = 0
      while column < maze.span.width {
        let point = CellPoint(x: column, y: row)
        if maze.tile(at: point) == .floor && point != maze.start && point != maze.stairs
          && !taken.contains(point)
        {
          spots.append(point)
        }
        column += 1
      }
      row += 1
    }
    return spots
  }

  private func phase(_ world: FloorWorld, _ point: CellPoint) -> FloorFixture.Phase? {
    for fixture in world.fixtures.fixtures where fixture.point == point {
      return fixture.phase
    }
    return nil
  }

  private func lane() -> FloorWorld {
    let span = GridSpan(width: 11, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var column = 1
    while column <= 6 {
      tiles[span.offset(CellPoint(x: column, y: 2))] = .floor
      column += 1
    }
    let start = CellPoint(x: 1, y: 2)
    let stairs = CellPoint(x: 6, y: 2)
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
    let pads = [
      FloorFixture(point: CellPoint(x: 2, y: 2), kind: .warp, phase: .sealed),
      FloorFixture(point: CellPoint(x: 5, y: 2), kind: .warp, phase: .sealed),
    ]
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: pads, wade: 0),
      aim: .explore)
  }
}
