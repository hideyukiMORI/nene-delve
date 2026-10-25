import Testing

@testable import NeNeDelveCore

struct BossHallTests {
  @Test func theFirstFloorHasNoBoss() {
    guard let world = resumed(1, depth: 1, span: GridSpan(width: 41, height: 21)) else {
      Issue.record("expected a floor")
      return
    }
    #expect(world.fixtures.prowlers.allSatisfy { !$0.boss })
    #expect(!BossHall.hosts(1))
    #expect(!BossHall.hosts(9))
    #expect(BossHall.hosts(10))
    #expect(BossHall.hosts(20))
    #expect(BossHall.hosts(30))
    #expect(DelverVitals.bossLife(depth: 10) == DelverVitals.foeLife(depth: 10, chases: true) * 2)
  }

  @Test(arguments: [UInt64(1), 9])
  func aNinthFloorDoesNotOpenAHall(raw: UInt64) {
    let span = GridSpan(width: 41, height: 21)
    guard let world = resumed(raw, depth: 9, span: span),
      let marked = preHall(raw, depth: 9, span: span)
    else {
      Issue.record("expected a floor")
      return
    }
    #expect(world.walk.maze == marked)
    #expect(world.fixtures.prowlers.allSatisfy { !$0.boss })
  }

  @Test(arguments: [UInt64(1), 9])
  func aTenthFloorOpensTheHallAfterFixtures(raw: UInt64) {
    let span = GridSpan(width: 41, height: 21)
    guard let world = resumed(raw, depth: 10, span: span),
      let marked = preHall(raw, depth: 10, span: span)
    else {
      Issue.record("expected a floor")
      return
    }
    let fresh = expectedFresh(marked)
    #expect(!fresh.isEmpty)
    guard !fresh.isEmpty, let stand = expectedStand(fresh, span: span) else {
      return
    }
    #expect(world.walk.maze.dug == marked.dug + fresh)
    #expect(world.walk.maze.ends.ascent == marked.ends.ascent)
    #expect(marked.tile(at: stand) == .wall)
    #expect(world.walk.maze.tile(at: stand) == .floor)
    #expect(DigReveal.maze(world.walk.maze, frame: 0).tile(at: stand) == .wall)
    let finished = DigReveal.maze(world.walk.maze, frame: DigReveal.frames - 1)
    #expect(finished == world.walk.maze)
    let placed = placedBeforeHall(raw, depth: 10, maze: marked)
    #expect(world.fixtures.fixtures == placed.fixtures)
    #expect(Array(world.fixtures.prowlers.dropLast()) == placed.prowlers)
    let boss = world.fixtures.prowlers.last
    #expect(boss?.boss == true)
    #expect(boss?.chases == false)
    #expect(boss?.point == stand)
    #expect(boss?.life == DelverVitals.bossLife(depth: 10))
    #expect(boss?.mood == .blink)
    let path = FloorRoute.firstStep(world.walk.maze, from: world.walk.maze.start, to: stand)
    #expect(path != nil)
  }

  @Test func aNarrowBossFloorStillPlacesFixturesFirst() {
    let span = GridSpan(width: 11, height: 9)
    guard let world = resumed(1, depth: 10, span: span),
      let marked = preHall(1, depth: 10, span: span)
    else {
      Issue.record("expected a floor")
      return
    }
    let placed = placedBeforeHall(1, depth: 10, maze: marked)
    #expect(world.fixtures.fixtures == placed.fixtures)
    let bosses = world.fixtures.prowlers.filter(\.boss)
    let opened = world.walk.maze != marked
    #expect(bosses.count == (opened ? 1 : 0))
    #expect(world.fixtures.prowlers.filter { !$0.boss } == placed.prowlers)
  }

  @Test func aThirtiethFloorStillSeeksTheAscent() {
    guard let world = resumed(1, depth: 30, span: GridSpan(width: 41, height: 21)) else {
      Issue.record("expected a floor")
      return
    }
    #expect(AscentSite.seeks(world))
    #expect(world.fixtures.prowlers.contains { $0.boss })
  }

  @Test func aBossFightContinuesPastTheUsualSpan() {
    guard var world = resumed(1, depth: 1, span: GridSpan(width: 21, height: 15)) else {
      Issue.record("expected a floor")
      return
    }
    guard let beside = neighbor(world) else {
      Issue.record("expected a neighboring floor")
      return
    }
    let origin = world.walk.explorer.position
    world = meet(world, beast: FloorProwler(bossAt: beside, mood: .blink, life: 80))
    guard let next = stepped(world, times: FloorProwler.fightSpan) else {
      Issue.record("the fight left the floor")
      return
    }
    #expect(next.walk.explorer.position == origin)
    #expect(next.fixtures.hold >= 1)
    let foe = next.fixtures.fighting()
    #expect(foe?.boss == true)
    #expect((foe?.life ?? 0) > 0)
    #expect((foe?.life ?? 80) < 80)
  }

  @Test func aFrailBossIsClearedOnTheFirstExchange() {
    guard var world = resumed(1, depth: 1, span: GridSpan(width: 21, height: 15)) else {
      Issue.record("expected a floor")
      return
    }
    guard let beside = neighbor(world) else {
      Issue.record("expected a neighboring floor")
      return
    }
    world = meet(world, beast: FloorProwler(bossAt: beside, mood: .blink, life: 1))
    guard let next = stepped(world, times: 1) else {
      Issue.record("the fight left the floor")
      return
    }
    #expect(next.fixtures.prowlers.isEmpty)
    #expect(next.fixtures.hold == 0)
  }

  @Test func aSeekingRunnerMeetsTheBossBeforeTheAscent() {
    let layout = branch()
    let boss = FloorProwler(bossAt: layout.stand, mood: .blink, life: 40)
    let world = seeking(layout.maze, prowlers: [boss], chests: [])
    #expect(AscentSite.seeks(world))
    #expect(world.fixtures.nearestBoss(to: layout.maze.start) == layout.stand)
    guard let next = stepped(world, times: 2) else {
      Issue.record("the runner left the floor")
      return
    }
    #expect(next.walk.explorer.position == CellPoint(x: 2, y: 2))
    #expect(next.fixtures.hold == FloorProwler.fightSpan)
    #expect(next.fixtures.fighting()?.boss == true)
  }

  @Test func aSealedChestStillComesBeforeTheBoss() {
    let layout = branch()
    let boss = FloorProwler(bossAt: layout.stand, mood: .blink, life: 40)
    let chest = FloorFixture(point: layout.chest, kind: .chest, phase: .sealed)
    let world = seeking(layout.maze, prowlers: [boss], chests: [chest])
    guard let next = stepped(world, times: 2) else {
      Issue.record("the runner left the floor")
      return
    }
    #expect(next.walk.explorer.position == CellPoint(x: 3, y: 1))
    #expect(next.fixtures.hold == 0)
  }

  private func resumed(_ raw: UInt64, depth: Int, span: GridSpan) -> FloorWorld? {
    guard
      case .world(let world) = FloorReducer.resume(
        launchSeed: Seed(raw: raw), floor: FloorIndex(depth: depth), span: span, pace: .explore)
    else {
      return nil
    }
    return world
  }

  private func preHall(_ raw: UInt64, depth: Int, span: GridSpan) -> Maze? {
    let floor = FloorIndex(depth: depth)
    let seed = Seed(raw: raw).forFloor(floor)
    guard
      case .maze(let maze) = MazeFactory.make(kind: MazeKind.chosen(seed), seed: seed, span: span)
    else {
      return nil
    }
    guard let point = AscentSite.point(in: maze, depth: depth) else {
      return maze
    }
    return maze.withAscent(point)
  }

  private func placedBeforeHall(_ raw: UInt64, depth: Int, maze: Maze) -> FloorFixtureField {
    let seed = Seed(raw: raw).forFloor(FloorIndex(depth: depth))
    return FloorFixtureField.placed(in: maze, seed: seed, depth: depth)
  }

  private func expectedFresh(_ maze: Maze) -> [CellPoint] {
    let span = maze.span
    let width = min(span.width - 2, max(9, span.width * 2 / 3))
    let height = min(span.height - 2, max(7, span.height * 2 / 3))
    let originX = 1 + (span.width - 2 - width) / 2
    let originY = 1 + (span.height - 2 - height) / 2
    var fresh: [CellPoint] = []
    var y = originY
    while y < originY + height {
      var x = originX
      while x < originX + width {
        let point = CellPoint(x: x, y: y)
        if maze.tile(at: point) == .wall {
          fresh.append(point)
        }
        x += 1
      }
      y += 1
    }
    return fresh
  }

  private func expectedStand(_ fresh: [CellPoint], span: GridSpan) -> CellPoint? {
    if fresh.isEmpty {
      return nil
    }
    let width = min(span.width - 2, max(9, span.width * 2 / 3))
    let height = min(span.height - 2, max(7, span.height * 2 / 3))
    let centerX = 1 + (span.width - 2 - width) / 2 + width / 2
    let centerY = 1 + (span.height - 2 - height) / 2 + height / 2
    var best = fresh[0]
    var bestDistance = abs(best.x - centerX) + abs(best.y - centerY)
    for point in fresh {
      let next = abs(point.x - centerX) + abs(point.y - centerY)
      if next < bestDistance {
        best = point
        bestDistance = next
      }
    }
    return best
  }

  private func meet(_ world: FloorWorld, beast: FloorProwler) -> FloorWorld {
    let caught = FloorFixtureField(
      fixtures: world.fixtures.fixtures, wade: world.fixtures.wade, prowlers: [beast]
    ).encountered(world.walk.explorer.position)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: caught, aim: world.aim)
  }

  private func neighbor(_ world: FloorWorld) -> CellPoint? {
    let origin = world.walk.explorer.position
    let steps = [
      CellPoint(x: 1, y: 0), CellPoint(x: -1, y: 0), CellPoint(x: 0, y: 1), CellPoint(x: 0, y: -1),
    ]
    for step in steps {
      let next = CellPoint(x: origin.x + step.x, y: origin.y + step.y)
      if world.walk.maze.span.contains(next) && world.walk.maze.tile(at: next) == .floor {
        return next
      }
    }
    return nil
  }

  private func stepped(_ world: FloorWorld, times: Int) -> FloorWorld? {
    var current = world
    var count = 0
    while count < times {
      switch FloorReducer.tick(current) {
      case .running(let next):
        current = next
      case .descended, .ascended, .stuck:
        return nil
      }
      count += 1
    }
    return current
  }

  private func branch() -> (maze: Maze, stand: CellPoint, chest: CellPoint) {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    let stand = CellPoint(x: 2, y: 3)
    let chest = CellPoint(x: 4, y: 1)
    let ascent = CellPoint(x: 5, y: 1)
    let stairs = CellPoint(x: 5, y: 3)
    let floors = [
      start, CellPoint(x: 2, y: 1), CellPoint(x: 3, y: 1), chest, CellPoint(x: 2, y: 2), stand,
    ]
    for point in floors {
      tiles[span.offset(point)] = .floor
    }
    tiles[span.offset(ascent)] = .stairs
    tiles[span.offset(stairs)] = .stairs
    let ends = MazeEnds(start: start, stairs: stairs, ascent: ascent)
    let maze = Maze(span: span, tiles: tiles, plate: MazePlate(ends: ends), kind: .filledGrid)
    return (maze, stand, chest)
  }

  private func seeking(_ maze: Maze, prowlers: [FloorProwler], chests: [FloorFixture]) -> FloorWorld
  {
    let floor = FloorIndex(depth: 3)
    let seed = Seed(raw: 1)
    let pin = DelverLine.QuipPin(seed: seed, floor: floor, place: maze.start)
    return FloorWorld(
      course: FloorCourse(
        launchSeed: seed, floor: floor, pace: .explore, delver: Delver.fresh(pin)),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: seed), steps: 0),
      fixtures: FloorFixtureField(fixtures: chests, wade: 0, prowlers: prowlers),
      aim: .explore)
  }
}
