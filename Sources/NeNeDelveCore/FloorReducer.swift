public enum FloorReducer {
  public static func begin(launchSeed: Seed, span: GridSpan) -> FloorOpening {
    resume(launchSeed: launchSeed, floor: .first, span: span, pace: StepPace.forSpan(span))
  }

  public static func resume(launchSeed: Seed, floor: FloorIndex, span: GridSpan, pace: StepPace)
    -> FloorOpening
  {
    switch MazeFactory.make(kind: .filledGrid, seed: launchSeed.forFloor(floor), span: span) {
    case .tooSmall:
      .tooSmall
    case .maze(let maze):
      .world(makeWorld(launchSeed: launchSeed, floor: floor, maze: maze, pace: pace))
    }
  }

  public static func tick(_ world: FloorWorld) -> FloorTick {
    if world.walk.steps > limit(world.walk.maze) {
      return .stuck
    }
    return stepped(world)
  }

  public static func nextFloor(_ world: FloorWorld) -> NextFloor {
    let floor = world.course.floor.deeper()
    let seed = world.course.launchSeed.forFloor(floor)
    switch MazeFactory.make(kind: .filledGrid, seed: seed, span: world.walk.maze.span) {
    case .tooSmall:
      return .stuck
    case .maze(let maze):
      let next = makeWorld(
        launchSeed: world.course.launchSeed,
        floor: floor,
        maze: maze,
        pace: world.course.pace
      )
      return .ready(next)
    }
  }

  private static func stepped(_ world: FloorWorld) -> FloorTick {
    var rng = world.walk.rng
    switch world.walk.explorer.step(world.walk.maze, rng: &rng) {
    case .moved(let explorer):
      return .running(replacing(world, explorer: explorer, rng: rng))
    case .arrived(let explorer):
      return .descended(replacing(world, explorer: explorer, rng: rng))
    case .stuck:
      return .stuck
    }
  }

  private static func makeWorld(launchSeed: Seed, floor: FloorIndex, maze: Maze, pace: StepPace)
    -> FloorWorld
  {
    let course = FloorCourse(launchSeed: launchSeed, floor: floor, pace: pace)
    let walk = FloorWalk(
      maze: maze,
      explorer: Explorer.begin(maze),
      rng: SplitMix64(seed: launchSeed.forFloor(floor)),
      steps: 0
    )
    return FloorWorld(course: course, walk: walk)
  }

  private static func replacing(_ world: FloorWorld, explorer: Explorer, rng: SplitMix64)
    -> FloorWorld
  {
    let walk = FloorWalk(
      maze: world.walk.maze,
      explorer: explorer,
      rng: rng,
      steps: world.walk.steps + 1
    )
    return FloorWorld(course: world.course, walk: walk)
  }

  private static func limit(_ maze: Maze) -> Int {
    maze.span.count * 2
  }
}
