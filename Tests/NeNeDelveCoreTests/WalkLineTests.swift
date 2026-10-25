import Testing

@testable import NeNeDelveCore

struct WalkLineTests {
  @Test func aStraightStepUsesTheDash() {
    let world = corridor(path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], next: CellPoint(x: 3, y: 2))
    #expect(WalkLine.continues(world))
    #expect(WalkLine.milliseconds(world) == StepPace.dash.milliseconds)
  }

  @Test func theOpeningStepKeepsTheFloorPace() {
    let world = corridor(path: [CellPoint(x: 1, y: 2)], next: CellPoint(x: 2, y: 2))
    #expect(!WalkLine.continues(world))
    #expect(WalkLine.milliseconds(world) == StepPace.explore.milliseconds)
  }

  @Test func aTurnKeepsTheFloorPace() {
    let world = corridor(path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], next: CellPoint(x: 2, y: 3))
    #expect(!WalkLine.continues(world))
    #expect(WalkLine.milliseconds(world) == StepPace.explore.milliseconds)
  }

  @Test func aFightKeepsTheFloorPace() {
    let world = corridor(
      path: [CellPoint(x: 1, y: 2), CellPoint(x: 2, y: 2)], next: CellPoint(x: 3, y: 2), hold: 1)
    #expect(!WalkLine.continues(world))
    #expect(WalkLine.milliseconds(world) == StepPace.explore.milliseconds)
  }

  private func corridor(path: [CellPoint], next: CellPoint, hold: Int = 0) -> FloorWorld {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    for point in path + [next] {
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
