import Testing

@testable import NeNeDelveCore

struct DeadEndTests {
  @Test func aTipMarksTheWallAhead() {
    let world = tip()
    #expect(DeadEnd.cap(world) == CellPoint(x: 3, y: 2))
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.wonder.milliseconds)
  }

  @Test func anOpenEntranceIsNotADeadEnd() {
    let world = entrance()
    #expect(DeadEnd.cap(world) == nil)
    let waited = WalkTempo.chosen(world, from: StepPace.dash.milliseconds)
    #expect(waited == StepPace.dash.milliseconds)
  }

  @Test func aFightAtTheTipKeepsTheFloorPace() {
    let world = tip(hold: 1)
    #expect(DeadEnd.cap(world) == CellPoint(x: 3, y: 2))
    #expect(!DeadEnd.leaving(world))
    let waited = WalkTempo.chosen(world, from: StepPace.explore.milliseconds)
    #expect(waited == StepPace.explore.milliseconds)
  }

  @Test func aLongerWaitStaysLongerAtTheTip() {
    let world = tip()
    #expect(WalkTempo.chosen(world, from: 200) == 200)
  }

  private func tip(hold: Int = 0) -> FloorWorld {
    stood(
      floors: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)],
      path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], hold: hold)
  }

  private func entrance() -> FloorWorld {
    stood(
      floors: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)],
      path: [CellPoint(x: 1, y: 2)], hold: 0)
  }

  private func stood(floors: [CellPoint], path: [CellPoint], hold: Int) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    for point in floors {
      tiles[span.offset(point)] = .floor
    }
    let stairs = CellPoint(x: 5, y: 1)
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: path[0], stairs: stairs), kind: .filledGrid)
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
