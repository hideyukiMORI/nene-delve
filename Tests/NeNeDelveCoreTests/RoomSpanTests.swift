import Testing

@testable import NeNeDelveCore

struct RoomSpanTests {
  @Test func anOpenSquareInRoomsIsARoom() {
    let maze = square(kind: .rooms)
    #expect(RoomSpan.contains(CellPoint(x: 1, y: 1), in: maze))
    #expect(RoomSpan.contains(CellPoint(x: 3, y: 3), in: maze))
    #expect(!RoomSpan.contains(CellPoint(x: 5, y: 1), in: maze))
  }

  @Test func aFilledSquareIsNotARoom() {
    let maze = square(kind: .filledGrid)
    #expect(!RoomSpan.contains(CellPoint(x: 2, y: 2), in: maze))
  }

  @Test func aStairInsideTheSquareIsARoom() {
    let maze = square(kind: .rooms, stair: CellPoint(x: 2, y: 2))
    #expect(RoomSpan.contains(CellPoint(x: 2, y: 2), in: maze))
  }

  @Test func aStraightRoomStepUsesTheLinger() {
    let world = room(
      path: [CellPoint(x: 1, y: 1), CellPoint(x: 2, y: 1)], next: CellPoint(x: 3, y: 1))
    #expect(RoomSpan.crossing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.linger.milliseconds)
  }

  @Test func aLongerWaitStaysLonger() {
    let world = room(
      path: [CellPoint(x: 1, y: 1), CellPoint(x: 2, y: 1)], next: CellPoint(x: 3, y: 1))
    #expect(WalkTempo.chosen(world, from: 167) == 167)
  }

  @Test func aFightInARoomKeepsTheFloorPace() {
    let world = room(
      path: [CellPoint(x: 1, y: 1), CellPoint(x: 2, y: 1)], next: CellPoint(x: 3, y: 1), hold: 1)
    #expect(!RoomSpan.crossing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.explore.milliseconds)
    #expect(waited == StepPace.explore.milliseconds)
  }

  @Test func aCorridorKeepsTheDash() {
    let world = lane(
      path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], next: CellPoint(x: 3, y: 2))
    #expect(!RoomSpan.crossing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.dash.milliseconds)
  }

  @Test func generatedRoomsHaveAnOpenSquare() {
    let plan = MazeFactory.rooms(seed: Seed(raw: 1), span: GridSpan(width: 41, height: 21))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    #expect(counted(maze) > 0)
  }

  @Test func aFilledGridHasNoRoom() {
    let plan = MazeFactory.filled(seed: Seed(raw: 9), span: GridSpan(width: 41, height: 21))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    #expect(counted(maze) == 0)
  }

  private func counted(_ maze: Maze) -> Int {
    var found = 0
    var y = 0
    while y < maze.span.height {
      var x = 0
      while x < maze.span.width {
        if RoomSpan.contains(CellPoint(x: x, y: y), in: maze) {
          found += 1
        }
        x += 1
      }
      y += 1
    }
    return found
  }

  private func square(kind: MazeKind, stair: CellPoint = CellPoint(x: 5, y: 1)) -> Maze {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var y = 1
    while y <= 3 {
      var x = 1
      while x <= 3 {
        tiles[span.offset(CellPoint(x: x, y: y))] = .floor
        x += 1
      }
      y += 1
    }
    tiles[span.offset(stair)] = .stairs
    return Maze(span: span, tiles: tiles, ends: MazeEnds(start: CellPoint(x: 1, y: 1), stairs: stair), kind: kind)
  }

  private func room(path: [CellPoint], next: CellPoint, hold: Int = 0) -> FloorWorld {
    stood(kind: .rooms, path: path, next: next, hold: hold, wide: true)
  }

  private func lane(path: [CellPoint], next: CellPoint) -> FloorWorld {
    stood(kind: .rooms, path: path, next: next, hold: 0, wide: false)
  }

  private func stood(
    kind: MazeKind, path: [CellPoint], next: CellPoint, hold: Int, wide: Bool
  ) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    for point in path + [next] {
      tiles[span.offset(point)] = .floor
    }
    if wide {
      var y = 1
      while y <= 3 {
        var x = 1
        while x <= 3 {
          tiles[span.offset(CellPoint(x: x, y: y))] = .floor
          x += 1
        }
        y += 1
      }
    }
    let stairs = CellPoint(x: 5, y: 3)
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: path[0], stairs: stairs), kind: kind)
    var seen = Array(repeating: false, count: span.count)
    for point in path {
      seen[span.offset(point)] = true
    }
    let explorer = Explorer(position: path[path.count - 1], path: path, seen: seen)
    let course = FloorCourse(
      launchSeed: Seed(raw: 1), floor: .first, pace: .explore, delver: .quiet)
    let walk = FloorWalk(
      maze: maze, explorer: explorer, rng: SplitMix64(seed: Seed(raw: 1)), steps: path.count)
    let fixtures = FloorFixtureField(fixtures: [], wade: 0, hold: hold)
    return FloorWorld(course: course, walk: walk, fixtures: fixtures, aim: .explore)
  }
}
