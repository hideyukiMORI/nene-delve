import Testing

@testable import NeNeDelveCore

struct StairApproachTests {
  @Test func theNeighborBeforeTheStairsSprints() {
    let world = lane(
      path: [CellPoint(x: 1, y: 2)], stairs: CellPoint(x: 3, y: 2),
      extra: [CellPoint(x: 2, y: 2)])
    #expect(StairApproach.closing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.sprint.milliseconds)
  }

  @Test func theStepOntoTheStairsSprints() {
    let world = lane(
      path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], stairs: CellPoint(x: 3, y: 2))
    #expect(StairApproach.closing(world))
    let waited = WalkTempo.chosen(world, from: 167)
    #expect(waited == StepPace.sprint.milliseconds)
  }

  @Test func aDistantStraightKeepsTheDash() {
    let world = lane(
      path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], stairs: CellPoint(x: 5, y: 1),
      extra: [CellPoint(x: 3, y: 2)])
    #expect(!StairApproach.closing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.dash.milliseconds)
  }

  @Test func aFightBesideTheStairsKeepsTheFloorPace() {
    let world = lane(
      path: [CellPoint(x: 1, y: 2)], stairs: CellPoint(x: 3, y: 2), hold: 1,
      extra: [CellPoint(x: 2, y: 2)])
    #expect(!StairApproach.closing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.explore.milliseconds)
    #expect(waited == StepPace.explore.milliseconds)
  }

  @Test func aRoomStillSprintsTowardTheStairs() {
    let world = roomTowardStairs()
    #expect(RoomSpan.crossing(world))
    #expect(StairApproach.closing(world))
    let waited = WalkTempo.chosen(world, from: StepPace.linger.milliseconds)
    #expect(waited == StepPace.sprint.milliseconds)
  }

  private func lane(
    path: [CellPoint], stairs: CellPoint, hold: Int = 0, extra: [CellPoint] = []
  ) -> FloorWorld {
    stood(floors: path + extra, path: path, stairs: stairs, hold: hold, wide: false)
  }

  private func roomTowardStairs() -> FloorWorld {
    let stairs = CellPoint(x: 3, y: 2)
    let path = [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)]
    return stood(floors: [], path: path, stairs: stairs, hold: 0, wide: true)
  }

  private func stood(
    floors: [CellPoint], path: [CellPoint], stairs: CellPoint, hold: Int, wide: Bool
  ) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    for point in floors {
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
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: path[0], stairs: stairs), kind: .rooms)
    var seen = Array(repeating: false, count: span.count)
    for point in path {
      seen[span.offset(point)] = true
    }
    if wide {
      var y = 1
      while y <= 3 {
        var x = 1
        while x <= 3 {
          let point = CellPoint(x: x, y: y)
          if point != stairs {
            seen[span.offset(point)] = true
          }
          x += 1
        }
        y += 1
      }
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
