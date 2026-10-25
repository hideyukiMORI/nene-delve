public struct FloorWorld: Equatable, Sendable {
  public let course: FloorCourse
  public let walk: FloorWalk
  public let fixtures: FloorFixtureField
  public let aim: WalkAim

  public init(
    course: FloorCourse, walk: FloorWalk, fixtures: FloorFixtureField, aim: WalkAim
  ) {
    self.course = course
    self.walk = walk
    self.fixtures = fixtures
    self.aim = aim
  }

  func replacing(maze: Maze) -> FloorWorld {
    let walk = FloorWalk(maze: maze, explorer: walk.explorer, rng: walk.rng, steps: walk.steps)
    return FloorWorld(course: course, walk: walk, fixtures: fixtures, aim: aim)
  }
}
