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
    let world = ShiftWall.turn(world)
    if world.walk.steps > limit(world.walk.maze) {
      return .stuck
    }
    if world.fixtures.burstMark() != nil {
      return .running(still(world, fixtures: world.fixtures.ageBurst()))
    }
    if let paused = world.fixtures.pausing() {
      return .running(still(world, fixtures: paused))
    }
    if world.fixtures.hold > 0 {
      return .running(bout(world))
    }
    if climbing(world, at: world.walk.explorer.position) {
      return .ascended(world)
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
      return .ready(carried(world, floor: floor, maze: maze, moment: .descend))
    }
  }

  public static func previousFloor(_ world: FloorWorld) -> NextFloor {
    guard let floor = world.course.floor.shallower() else {
      return .stuck
    }
    let seed = world.course.launchSeed.forFloor(floor)
    switch carved(seed: seed, span: world.walk.maze.span) {
    case .tooSmall:
      return .stuck
    case .maze(let maze):
      return .ready(carried(world, floor: floor, maze: maze, moment: .ascend))
    }
  }

  private struct Step {
    let walk: FloorWalk
    let fixtures: FloorFixtureField
    let delver: Delver
    let aim: WalkAim
  }

  private static func explore(_ world: FloorWorld) -> FloorTick {
    var rng = world.walk.rng
    let bias = StepBias(
      lure: lure(world), avoid: world.fixtures.lakePoints(), blocked: gate(world))
    switch world.walk.explorer.step(
      world.walk.maze, rng: &rng, avoidStairs: world.fixtures.holdsSealed, bias: bias)
    {
    case .moved(let explorer):
      return moved(world, explorer: explorer, rng: rng, aim: .explore)
    case .arrived(let explorer):
      return finish(world, explorer: explorer, rng: rng)
    case .stuck:
      return recover(world)
    }
  }

  private static func recover(_ world: FloorWorld) -> FloorTick {
    if world.fixtures.sealed(at: world.walk.explorer.position) {
      return moved(world, explorer: world.walk.explorer, rng: world.walk.rng, aim: .recover)
    }
    let origin = world.walk.explorer.position
    let target = world.fixtures.nearestSealed(to: origin) ?? destination(world)
    guard let next = FloorRoute.firstStep(world.walk.maze, from: origin, to: target) else {
      return .stuck
    }
    switch world.walk.explorer.move(to: next, maze: world.walk.maze) {
    case .moved(let explorer):
      return moved(world, explorer: explorer, rng: world.walk.rng, aim: .recover)
    case .arrived(let explorer):
      return finish(world, explorer: explorer, rng: world.walk.rng)
    case .stuck:
      return .stuck
    }
  }

  private static func moved(
    _ world: FloorWorld, explorer: Explorer, rng: SplitMix64, aim: WalkAim
  ) -> FloorTick {
    if climbing(world, at: explorer.position) {
      return .ascended(arrived(world, explorer: explorer, rng: rng))
    }
    if world.fixtures.exit(from: explorer.position) != nil {
      return flung(world, explorer: explorer, rng: rng, aim: aim)
    }
    let delver = DelverMoment.notice(world, explorer: explorer)
    let fixtures = aftermath(world, explorer: explorer)
    let step = Step(
      walk: walked(world, explorer: explorer, rng: rng), fixtures: fixtures, delver: delver,
      aim: aim
    )
    return .running(commit(world, step))
  }

  private static func flung(
    _ world: FloorWorld, explorer: Explorer, rng: SplitMix64, aim: WalkAim
  ) -> FloorTick {
    guard let far = world.fixtures.exit(from: explorer.position) else {
      return .stuck
    }
    let landed = explorer.jump(to: far, maze: world.walk.maze)
    let spoken = DelverMoment.glitch(world, place: far)
    let field =
      world.fixtures.jumped(from: explorer.position, to: far)
      .hunted(far, in: world.walk.maze)
      .encountered(far)
    let step = Step(
      walk: walked(world, explorer: landed, rng: rng), fixtures: field, delver: spoken, aim: aim)
    return .running(commit(world, step))
  }

  private static func aftermath(_ world: FloorWorld, explorer: Explorer) -> FloorFixtureField {
    let place = explorer.position
    if world.fixtures.mimic(at: place) {
      let hunted = world.fixtures.hunted(place, in: world.walk.maze)
      return hunted.bitten(at: place, depth: world.course.floor.depth, in: world.walk.maze)
        .encountered(place)
    }
    let opened =
      world.fixtures.sealed(at: place) ? world.fixtures.beginBurst(at: place) : world.fixtures
    let sprung = world.fixtures.pit(at: place) ? opened.spring(at: place) : opened
    return sprung.entered(place).hunted(place, in: world.walk.maze).encountered(place)
  }

  private static func arrived(_ world: FloorWorld, explorer: Explorer, rng: SplitMix64)
    -> FloorWorld
  {
    let step = Step(
      walk: walked(world, explorer: explorer, rng: rng), fixtures: world.fixtures,
      delver: world.course.delver.aged(), aim: world.aim)
    return commit(world, step)
  }

  private static func still(_ world: FloorWorld, fixtures: FloorFixtureField) -> FloorWorld {
    let step = Step(
      walk: walked(world, explorer: world.walk.explorer, rng: world.walk.rng), fixtures: fixtures,
      delver: world.course.delver.aged(), aim: world.aim)
    return commit(world, step)
  }

  private static func bout(_ world: FloorWorld) -> FloorWorld {
    let outcome = DelverBout.step(world)
    let step = Step(
      walk: walked(world, explorer: world.walk.explorer, rng: world.walk.rng),
      fixtures: outcome.field, delver: outcome.delver, aim: world.aim)
    return commit(world, step)
  }

  private static func commit(_ world: FloorWorld, _ step: Step) -> FloorWorld {
    FloorWorld(
      course: world.course.with(delver: step.delver.noted()), walk: step.walk,
      fixtures: step.fixtures,
      aim: step.aim)
  }

  private static func walked(_ world: FloorWorld, explorer: Explorer, rng: SplitMix64) -> FloorWalk
  {
    FloorWalk(
      maze: world.walk.maze, explorer: explorer, rng: rng, steps: world.walk.steps + 1)
  }

  private static func makeWorld(launchSeed: Seed, floor: FloorIndex, maze: Maze, pace: StepPace)
    -> FloorWorld
  {
    let marked = stamped(maze, floor: floor)
    let floorSeed = launchSeed.forFloor(floor)
    let field = FloorFixtureField.placed(in: marked, seed: floorSeed, depth: floor.depth)
    let hall = BossHall.carve(marked, depth: floor.depth)
    let explorer = Explorer.begin(hall.maze)
    let pin = DelverLine.QuipPin(seed: launchSeed, floor: floor, place: explorer.position)
    let course = FloorCourse(
      launchSeed: launchSeed, floor: floor, pace: pace, delver: Delver.fresh(pin))
    let walk = FloorWalk(
      maze: hall.maze, explorer: explorer, rng: SplitMix64(seed: floorSeed), steps: 0)
    let fixtures = field.posting(hall.stand, depth: floor.depth)
    return FloorWorld(course: course, walk: walk, fixtures: fixtures, aim: .explore)
  }

  private static func stamped(_ maze: Maze, floor: FloorIndex) -> Maze {
    guard let point = AscentSite.point(in: maze, depth: floor.depth) else {
      return maze
    }
    return maze.withAscent(point)
  }

  private static func carried(
    _ world: FloorWorld, floor: FloorIndex, maze: Maze, moment: DelverLine.Moment
  ) -> FloorWorld {
    let born = makeWorld(
      launchSeed: world.course.launchSeed, floor: floor, maze: maze, pace: world.course.pace)
    let pin = DelverLine.QuipPin(
      seed: world.course.launchSeed, floor: floor, place: born.walk.explorer.position)
    let spoken = world.course.delver.carrying(
      vitals: world.course.delver.vitals.rested(),
      line: DelverLine.say(moment, pin: pin, note: floor.depth)
    ).reaching(max(world.course.floor.depth, floor.depth))
    let marked = moment == .ascend ? spoken.remembering(world.course.floor.depth) : spoken
    return FloorWorld(
      course: born.course.with(delver: marked.noted()), walk: born.walk, fixtures: born.fixtures,
      aim: born.aim)
  }

  private static func lure(_ world: FloorWorld) -> CellPoint? {
    if let chest = world.fixtures.nearestSealed(to: world.walk.explorer.position) {
      return chest
    }
    if let boss = world.fixtures.nearestBoss(to: world.walk.explorer.position) {
      return boss
    }
    if AscentSite.seeks(world) {
      return world.walk.maze.ends.ascent
    }
    return world.fixtures.nearestWarp(to: world.walk.explorer.position)
  }

  private static func gate(_ world: FloorWorld) -> CellPoint? {
    if AscentSite.seeks(world) {
      return world.walk.maze.stairs
    }
    return nil
  }

  private static func destination(_ world: FloorWorld) -> CellPoint {
    if AscentSite.seeks(world), let up = world.walk.maze.ends.ascent {
      return up
    }
    return world.walk.maze.stairs
  }

  private static func climbing(_ world: FloorWorld, at place: CellPoint) -> Bool {
    if !AscentSite.seeks(world) || world.fixtures.holdsSealed {
      return false
    }
    return place == world.walk.maze.ends.ascent
  }

  private static func finish(_ world: FloorWorld, explorer: Explorer, rng: SplitMix64) -> FloorTick
  {
    if explorer.position == world.walk.maze.ends.ascent {
      return moved(world, explorer: explorer, rng: rng, aim: world.aim)
    }
    return .descended(arrived(world, explorer: explorer, rng: rng))
  }

  private static func carved(seed: Seed, span: GridSpan) -> MazePlan {
    MazeFactory.make(kind: MazeKind.chosen(seed), seed: seed, span: span)
  }

  private static func limit(_ maze: Maze) -> Int {
    maze.span.count * 2
  }
}
