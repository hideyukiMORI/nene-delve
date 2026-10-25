/// 動く壁。歩数が周期の倍数のときだけ、時計は読まない。
enum ShiftWall {
  static let period = 24

  static func turn(_ world: FloorWorld) -> FloorWorld {
    let maze = world.walk.maze
    if maze.kind != .shifting || !due(world.walk.steps) {
      return world
    }
    return world.replacing(maze: maze.cycled(keeping: blocked(world)))
  }

  private static func due(_ steps: Int) -> Bool {
    steps > 0 && steps.isMultiple(of: period)
  }

  private static func blocked(_ world: FloorWorld) -> [CellPoint] {
    var points = [world.walk.explorer.position]
    for prowler in world.fixtures.prowlers {
      points.append(prowler.point)
    }
    for fixture in world.fixtures.fixtures {
      points.append(fixture.point)
    }
    return points
  }
}
