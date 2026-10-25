import Testing

@testable import NeNeDelveCore

struct AscentSiteTests {
  @Test func theFirstFloorHasNoUpStair() {
    let span = GridSpan(width: 21, height: 15)
    guard case .world(let world) = FloorReducer.begin(launchSeed: Seed(raw: 1), span: span) else {
      Issue.record("expected a world")
      return
    }
    #expect(world.walk.maze.ends.ascent == nil)
    #expect(!AscentSite.seeks(world))
    #expect(FloorReducer.previousFloor(world) == .stuck)
  }

  @Test func theUpStairIsTheFarFloorCell() {
    let span = GridSpan(width: 5, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    let stairs = CellPoint(x: 1, y: 3)
    let near = CellPoint(x: 1, y: 2)
    let far = CellPoint(x: 3, y: 1)
    let tied = CellPoint(x: 4, y: 2)
    for cell in [start, near, far, tied] {
      tiles[span.offset(cell)] = .floor
    }
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
    #expect(AscentSite.point(in: maze, depth: 1) == nil)
    #expect(AscentSite.point(in: maze, depth: 2) == far)
    let marked = maze.withAscent(far)
    #expect(marked.ends.ascent == far)
    #expect(marked.tile(at: far) == .stairs)
    #expect(marked.tile(at: stairs) == .stairs)
    #expect(marked.tile(at: near) == .floor)
  }

  @Test func theThirdFloorOpensTheChestThenClimbs() {
    guard case .ascended(let stood) = walk(bridge(depth: 3)) else {
      Issue.record("the third floor did not climb")
      return
    }
    #expect(stood.walk.explorer.position == stood.walk.maze.ends.ascent)
    #expect(chestsAreOpen(stood))
    guard case .ready(let above) = FloorReducer.previousFloor(stood) else {
      Issue.record("the climb had no floor")
      return
    }
    #expect(above.course.floor.depth == 2)
    #expect(above.course.delver.risen == 3)
    #expect(above.course.delver.line.moment == .ascend)
    #expect(above.course.delver.line.note == 2)
    #expect(above.course.delver.vitals == stood.course.delver.vitals.rested())
    #expect(above.course.launchSeed == stood.course.launchSeed)
  }

  @Test func theSecondFloorCrossesTheUpStairAndDescends() {
    guard case .descended(let stood) = walk(bridge(depth: 2)) else {
      Issue.record("the second floor did not descend")
      return
    }
    #expect(stood.walk.explorer.position == stood.walk.maze.stairs)
    #expect(chestsAreOpen(stood))
  }

  @Test func theSameDepthDoesNotClimbTwice() {
    guard case .ascended(let stood) = walk(bridge(depth: 3)) else {
      Issue.record("the third floor did not climb")
      return
    }
    guard case .ready(let above) = FloorReducer.previousFloor(stood) else {
      Issue.record("the climb had no floor")
      return
    }
    let base = bridge(depth: 3)
    let again = FloorWorld(
      course: base.course.with(delver: above.course.delver), walk: base.walk,
      fixtures: base.fixtures, aim: .explore)
    #expect(!AscentSite.seeks(again))
    guard case .descended(let down) = walk(again) else {
      Issue.record("the third floor climbed twice")
      return
    }
    #expect(down.walk.explorer.position == down.walk.maze.stairs)
  }

  @Test func onlyEveryThirdDepthSeeksTheUpStair() {
    #expect(AscentSite.seeks(bridge(depth: 6)))
    #expect(!AscentSite.seeks(bridge(depth: 4)))
    let sixth = bridge(depth: 6)
    let remembered = FloorWorld(
      course: sixth.course.with(delver: Delver(vitals: .fresh(), line: .quiet, risen: 6)),
      walk: sixth.walk, fixtures: sixth.fixtures, aim: .explore)
    #expect(!AscentSite.seeks(remembered))
  }

  @Test(arguments: [UInt64(1), 9])
  func aDeeperFloorReturnsToTheSameMaze(raw: UInt64) {
    guard case .world(let third) = resume(raw, depth: 3) else {
      Issue.record("expected a floor")
      return
    }
    #expect(AscentSite.seeks(third))
    guard case .ascended(let stood) = walk(third) else {
      Issue.record("seed \(raw) did not climb")
      return
    }
    #expect(stood.walk.explorer.position == stood.walk.maze.ends.ascent)
    guard case .ready(let above) = FloorReducer.previousFloor(stood) else {
      Issue.record("the climb had no floor")
      return
    }
    guard case .world(let direct) = resume(raw, depth: 2) else {
      Issue.record("expected the floor above")
      return
    }
    #expect(above.walk.maze == direct.walk.maze)
    #expect(above.course.delver.risen == 3)
    #expect(direct.walk.maze.ends.ascent != nil)
    #expect(!AscentSite.seeks(direct))
  }

  private func resume(_ raw: UInt64, depth: Int) -> FloorOpening {
    let span = GridSpan(width: 21, height: 15)
    return FloorReducer.resume(
      launchSeed: Seed(raw: raw), floor: FloorIndex(depth: depth), span: span, pace: .explore)
  }

  private func bridge(depth: Int) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 2)
    let up = CellPoint(x: 2, y: 2)
    let chest = CellPoint(x: 3, y: 2)
    let stairs = CellPoint(x: 1, y: 1)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(up)] = .floor
    tiles[span.offset(chest)] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid
    ).withAscent(up)
    let field = FloorFixtureField(
      fixtures: [FloorFixture(point: chest, kind: .chest, phase: .sealed)], wade: 0)
    return FloorWorld(
      course: FloorCourse(
        launchSeed: Seed(raw: 1), floor: FloorIndex(depth: depth), pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: field, aim: .explore)
  }

  private func walk(_ start: FloorWorld) -> FloorTick {
    var world = start
    let bound = world.walk.maze.span.count * 2
    var ticks = 0
    while ticks <= bound {
      ticks += 1
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended(let stood):
        return .descended(stood)
      case .ascended(let stood):
        return .ascended(stood)
      case .stuck:
        return .stuck
      }
    }
    return .stuck
  }

  private func chestsAreOpen(_ world: FloorWorld) -> Bool {
    for fixture in world.fixtures.fixtures {
      switch fixture.phase {
      case .sealed, .bursting:
        return false
      case .open:
        break
      }
    }
    return true
  }
}
