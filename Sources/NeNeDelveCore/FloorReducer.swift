public enum FloorReducer {
  public static func begin(launchSeed: Seed, span: GridSpan) -> FloorOpening {
    resume(launchSeed: launchSeed, floor: .first, span: span, pace: StepPace.forSpan(span))
  }

  public static func resume(launchSeed: Seed, floor: FloorIndex, span: GridSpan, pace: StepPace)
    -> FloorOpening
  {
    switch carved(seed: launchSeed.forFloor(floor), span: span) {
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
    if world.fixtures.burstMark() != nil {
      let aged = advanced(
        world, explorer: world.walk.explorer, rng: world.walk.rng,
        fixtures: world.fixtures.ageBurst()
      )
      return .running(aged)
    }
    if let paused = world.fixtures.pausing() {
      let held = advanced(
        world, explorer: world.walk.explorer, rng: world.walk.rng, fixtures: paused)
      return .running(held)
    }
    switch world.aim {
    case .explore:
      return explore(world)
    case .recover:
      return recover(world)
    }
  }

  public static func nextFloor(_ world: FloorWorld) -> NextFloor {
    let floor = world.course.floor.deeper()
    let seed = world.course.launchSeed.forFloor(floor)
    switch carved(seed: seed, span: world.walk.maze.span) {
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

  private static func explore(_ world: FloorWorld) -> FloorTick {
    var rng = world.walk.rng
    let lure = world.fixtures.nearestSealed(to: world.walk.explorer.position)
    let bias = StepBias(lure: lure, avoid: world.fixtures.lakePoints())
    switch world.walk.explorer.step(
      world.walk.maze, rng: &rng, avoidStairs: world.fixtures.holdsSealed, bias: bias)
    {
    case .moved(let explorer):
      return moved(world, explorer: explorer, rng: rng, aim: .explore)
    case .arrived(let explorer):
      return .descended(advanced(world, explorer: explorer, rng: rng, fixtures: world.fixtures))
    case .stuck:
      return recover(world)
    }
  }

  private static func recover(_ world: FloorWorld) -> FloorTick {
    if world.fixtures.sealed(at: world.walk.explorer.position) {
      return moved(world, explorer: world.walk.explorer, rng: world.walk.rng, aim: .recover)
    }
    let origin = world.walk.explorer.position
    let target = world.fixtures.nearestSealed(to: origin) ?? world.walk.maze.stairs
    guard let next = FloorRoute.firstStep(world.walk.maze, from: origin, to: target) else {
      return .stuck
    }
    switch world.walk.explorer.move(to: next, maze: world.walk.maze) {
    case .moved(let explorer):
      return moved(world, explorer: explorer, rng: world.walk.rng, aim: .recover)
    case .arrived(let explorer):
      return .descended(
        advanced(world, explorer: explorer, rng: world.walk.rng, fixtures: world.fixtures))
    case .stuck:
      return .stuck
    }
  }

  private static func moved(
    _ world: FloorWorld, explorer: Explorer, rng: SplitMix64, aim: WalkAim
  ) -> FloorTick {
    let opened =
      world.fixtures.sealed(at: explorer.position)
      ? world.fixtures.beginBurst(at: explorer.position)
      : world.fixtures
    let fixtures = opened.entered(explorer.position)
    let stepped = advanced(world, explorer: explorer, rng: rng, fixtures: fixtures)
    return .running(retarget(stepped, aim: aim))
  }

  private static func makeWorld(launchSeed: Seed, floor: FloorIndex, maze: Maze, pace: StepPace)
    -> FloorWorld
  {
    let floorSeed = launchSeed.forFloor(floor)
    let course = FloorCourse(launchSeed: launchSeed, floor: floor, pace: pace)
    let walk = FloorWalk(
      maze: maze,
      explorer: Explorer.begin(maze),
      rng: SplitMix64(seed: floorSeed),
      steps: 0
    )
    let fixtures = FloorFixtureField.placed(in: maze, seed: floorSeed)
    return FloorWorld(course: course, walk: walk, fixtures: fixtures, aim: .explore)
  }

  private static func advanced(
    _ world: FloorWorld, explorer: Explorer, rng: SplitMix64, fixtures: FloorFixtureField
  ) -> FloorWorld {
    let walk = FloorWalk(
      maze: world.walk.maze,
      explorer: explorer,
      rng: rng,
      steps: world.walk.steps + 1
    )
    return FloorWorld(course: world.course, walk: walk, fixtures: fixtures, aim: world.aim)
  }

  private static func retarget(_ world: FloorWorld, aim: WalkAim) -> FloorWorld {
    FloorWorld(course: world.course, walk: world.walk, fixtures: world.fixtures, aim: aim)
  }

  private static func carved(seed: Seed, span: GridSpan) -> MazePlan {
    MazeFactory.make(kind: MazeKind.chosen(seed), seed: seed, span: span)
  }

  private static func limit(_ maze: Maze) -> Int {
    maze.span.count * 2
  }
}
