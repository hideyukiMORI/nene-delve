import Testing

@testable import NeNeDelveCore

struct ExplorerTests {
  @Test func prefersAnUnvisitedCellAndCanMissTheStairs() {
    let maze = fork()
    var missed = false
    var tookStairs = false
    for raw in 0..<40 {
      var rng = SplitMix64(seed: Seed(raw: UInt64(raw)))
      switch Explorer.begin(maze).step(maze, rng: &rng) {
      case .moved(let explorer):
        #expect(explorer.position == CellPoint(x: 3, y: 2))
        missed = true
      case .arrived(let explorer):
        #expect(explorer.position == CellPoint(x: 2, y: 1))
        tookStairs = true
      case .stuck:
        Issue.record("the fork has a way out")
      }
    }
    #expect(missed)
    #expect(tookStairs)
  }

  @Test(arguments: [1, 8, 40, 2_048])
  func runnerArrivesWithinTheBound(raw: Int) {
    let span = GridSpan(width: 21, height: 15)
    guard case .world(var world) = FloorReducer.begin(launchSeed: Seed(raw: UInt64(raw)), span: span) else {
      Issue.record("expected a world")
      return
    }
    let positions = walk(&world)
    #expect(positions.count > 2)
    #expect(world.walk.explorer.position == world.walk.maze.stairs)
  }

  @Test func theSameSeedWalksTheSamePath() {
    let span = GridSpan(width: 17, height: 11)
    let first = positions(seed: 11, span: span)
    let second = positions(seed: 11, span: span)
    #expect(first == second)
    #expect(first != positions(seed: 12, span: span))
  }

  private func positions(seed: UInt64, span: GridSpan) -> [CellPoint] {
    guard case .world(var world) = FloorReducer.begin(launchSeed: Seed(raw: seed), span: span) else {
      return []
    }
    return walk(&world)
  }

  private func walk(_ world: inout FloorWorld) -> [CellPoint] {
    var positions = [world.walk.explorer.position]
    let bound = world.walk.maze.span.count * 2
    while positions.count <= bound {
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
        positions.append(next.walk.explorer.position)
      case .descended(let next):
        world = next
        positions.append(next.walk.explorer.position)
        return positions
      case .stuck:
        return []
      }
    }
    return []
  }

  private func fork() -> Maze {
    let span = GridSpan(width: 5, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 2, y: 2)
    let stairs = CellPoint(x: 2, y: 1)
    let side = CellPoint(x: 3, y: 2)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(stairs)] = .stairs
    tiles[span.offset(side)] = .floor
    return Maze(span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
  }
}
