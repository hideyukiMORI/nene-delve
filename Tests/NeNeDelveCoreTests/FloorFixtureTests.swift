import Testing

@testable import NeNeDelveCore

struct FloorFixtureTests {
  @Test func theSameSeedPlacesTheSameChests() {
    let span = GridSpan(width: 41, height: 21)
    let first = opened(1, span: span)
    let second = opened(1, span: span)
    #expect(first?.fixtures == second?.fixtures)
    #expect(first?.fixtures != opened(2, span: span)?.fixtures)
  }

  @Test func chestsSitOnOrdinaryFloors() {
    guard let world = opened(1, span: GridSpan(width: 41, height: 21)) else {
      Issue.record("expected a world")
      return
    }
    var chests = 0
    for fixture in world.fixtures.fixtures {
      #expect(world.walk.maze.tile(at: fixture.point) == .floor)
      #expect(fixture.point != world.walk.maze.start)
      #expect(fixture.point != world.walk.maze.stairs)
      switch fixture.kind {
      case .chest:
        chests += 1
        #expect(fixture.phase == .sealed)
      case .lake:
        #expect(fixture.phase == .open)
      }
    }
    #expect(chests >= 1)
    #expect(chests <= 3)
  }

  @Test func someFloorsHaveALakeAndADryStone() {
    var withLake = 0
    var without = 0
    for raw in 1...24 {
      guard let world = opened(UInt64(raw), span: GridSpan(width: 41, height: 21)) else {
        Issue.record("expected a world")
        return
      }
      let lakes = lakePoints(world)
      if lakes.isEmpty {
        without += 1
      } else {
        withLake += 1
        #expect(lakes.count >= 3)
        #expect(lakes.count < FloorFixtureField.pondCap)
        #expect(stone(world, lakes: lakes))
      }
    }
    #expect(withLake > 0)
    #expect(without > 0)
  }

  @Test func theSameSeedPlacesTheSameProwler() {
    let span = GridSpan(width: 41, height: 21)
    let first = opened(1, span: span)
    let second = opened(1, span: span)
    #expect(first?.fixtures.prowlers == second?.fixtures.prowlers)
    var differed = false
    for raw in 2...12 {
      if opened(UInt64(raw), span: span)?.fixtures.prowlers != first?.fixtures.prowlers {
        differed = true
      }
    }
    #expect(differed)
  }

  @Test func someFloorsHaveAProwler() {
    var withBeast = 0
    var without = 0
    var chases = 0
    var stands = 0
    for raw in 1...36 {
      guard let world = opened(UInt64(raw), span: GridSpan(width: 41, height: 21)) else {
        Issue.record("expected a world")
        return
      }
      let beasts = world.fixtures.prowlers
      if beasts.isEmpty {
        without += 1
        continue
      }
      withBeast += 1
      #expect(beasts.count == 1)
      let beast = beasts[0]
      #expect(world.walk.maze.tile(at: beast.point) == .floor)
      #expect(beast.point != world.walk.maze.start)
      #expect(beast.point != world.walk.maze.stairs)
      #expect(!world.fixtures.lake(at: beast.point))
      #expect(!world.fixtures.sealed(at: beast.point))
      switch beast.mood {
      case .blink:
        break
      case .fight, .flee, .gone:
        Issue.record("a new prowler should blink")
      }
      if beast.chases {
        chases += 1
      } else {
        stands += 1
      }
    }
    #expect(withBeast > 0)
    #expect(without > 0)
    #expect(chases > 0)
    #expect(stands > 0)
  }

  @Test func aFightHoldsTheRunnerThenEnds() {
    guard var world = opened(1, span: GridSpan(width: 21, height: 15)) else {
      Issue.record("expected a world")
      return
    }
    guard let beside = beside(world) else {
      Issue.record("expected a neighboring floor")
      return
    }
    world = meet(world, beast: FloorProwler(point: beside, chases: false, mood: .blink))
    let origin = world.walk.explorer.position
    #expect(world.fixtures.hold == FloorProwler.fightSpan)
    var ticks = 0
    while ticks < FloorProwler.fightSpan {
      ticks += 1
      switch FloorReducer.tick(world) {
      case .running(let next):
        #expect(next.walk.explorer.position == origin)
        world = next
      case .descended, .stuck:
        Issue.record("the fight ended the floor")
        return
      }
    }
    #expect(world.fixtures.prowlers.isEmpty)
    #expect(world.fixtures.hold == 0)
  }

  @Test func aChaserFleesAndThenVanishes() {
    guard var world = opened(1, span: GridSpan(width: 21, height: 15)) else {
      Issue.record("expected a world")
      return
    }
    guard let beside = beside(world) else {
      Issue.record("expected a neighboring floor")
      return
    }
    world = meet(world, beast: FloorProwler(point: beside, chases: true, mood: .blink))
    var ticks = 0
    while ticks < FloorProwler.fightSpan {
      ticks += 1
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended, .stuck:
        Issue.record("the fight ended the floor")
        return
      }
    }
    #expect(!world.fixtures.prowlers.isEmpty)
    while ticks < FloorProwler.fightSpan + FloorProwler.fleeSpan {
      ticks += 1
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended, .stuck:
        Issue.record("the flight ended the floor")
        return
      }
    }
    #expect(world.fixtures.prowlers.isEmpty)
  }

  @Test func aChaserStepsCloser() {
    guard let world = opened(1, span: GridSpan(width: 41, height: 21)) else {
      Issue.record("expected a world")
      return
    }
    guard let far = distantFloor(world) else {
      Issue.record("expected a distant floor")
      return
    }
    let beast = FloorProwler(point: far, chases: true, mood: .blink)
    let chased = FloorFixtureField(fixtures: [], wade: 0, prowlers: [beast]).hunted(
      world.walk.explorer.position, in: world.walk.maze)
    #expect(chased.prowlers[0].point != far)
  }

  @Test func wadingPausesOnALake() {
    let point = CellPoint(x: 2, y: 2)
    let lake = FloorFixture(point: point, kind: .lake, phase: .open)
    let field = FloorFixtureField(fixtures: [lake], wade: 0).entered(point)
    #expect(field.wade == FloorFixture.wadeSpan)
    #expect(field.pausing()?.wade == FloorFixture.wadeSpan - 1)
    #expect(field.entered(CellPoint(x: 0, y: 0)).wade == FloorFixture.wadeSpan)
  }

  @Test func aTinyFloorStaysEmpty() {
    guard let world = opened(1, span: GridSpan(width: 5, height: 5)) else {
      Issue.record("expected a world")
      return
    }
    #expect(world.fixtures.fixtures.isEmpty)
  }

  @Test func chestsOpenBeforeTheStairs() {
    guard var world = opened(1, span: GridSpan(width: 21, height: 15)) else {
      Issue.record("expected a world")
      return
    }
    #expect(!world.fixtures.fixtures.isEmpty)
    let bound = world.walk.maze.span.count * 2
    var ticks = 0
    while ticks <= bound {
      ticks += 1
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended(let next):
        #expect(next.walk.explorer.position == next.walk.maze.stairs)
        #expect(allOpen(next.fixtures))
        return
      case .stuck:
        Issue.record("chests left the runner stuck")
        return
      }
    }
    Issue.record("the runner did not reach the stairs")
  }

  private func opened(_ raw: UInt64, span: GridSpan) -> FloorWorld? {
    guard case .world(let world) = FloorReducer.begin(launchSeed: Seed(raw: raw), span: span) else {
      return nil
    }
    return world
  }

  private func meet(_ world: FloorWorld, beast: FloorProwler) -> FloorWorld {
    let caught = FloorFixtureField(
      fixtures: world.fixtures.fixtures, wade: world.fixtures.wade, prowlers: [beast]
    ).encountered(world.walk.explorer.position)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: caught, aim: world.aim)
  }

  private func beside(_ world: FloorWorld) -> CellPoint? {
    let origin = world.walk.explorer.position
    let steps = [
      CellPoint(x: 1, y: 0), CellPoint(x: -1, y: 0), CellPoint(x: 0, y: 1),
      CellPoint(x: 0, y: -1),
    ]
    for step in steps {
      let next = CellPoint(x: origin.x + step.x, y: origin.y + step.y)
      if world.walk.maze.span.contains(next) && world.walk.maze.tile(at: next) == .floor {
        return next
      }
    }
    return nil
  }

  private func distantFloor(_ world: FloorWorld) -> CellPoint? {
    let runner = world.walk.explorer.position
    let maze = world.walk.maze
    var row = 0
    while row < maze.span.height {
      var column = 0
      while column < maze.span.width {
        let point = CellPoint(x: column, y: row)
        let distance = abs(point.x - runner.x) + abs(point.y - runner.y)
        if distance >= 4 && maze.tile(at: point) == .floor
          && FloorRoute.firstStep(maze, from: point, to: runner) != nil
        {
          return point
        }
        column += 1
      }
      row += 1
    }
    return nil
  }

  private func lakePoints(_ world: FloorWorld) -> [CellPoint] {
    var points: [CellPoint] = []
    for fixture in world.fixtures.fixtures {
      switch fixture.kind {
      case .lake:
        points.append(fixture.point)
      case .chest:
        break
      }
    }
    return points
  }

  private func stone(_ world: FloorWorld, lakes: [CellPoint]) -> Bool {
    let steps = [
      CellPoint(x: 1, y: 0), CellPoint(x: -1, y: 0), CellPoint(x: 0, y: 1),
      CellPoint(x: 0, y: -1),
    ]
    for point in lakes {
      for step in steps {
        let next = CellPoint(x: point.x + step.x, y: point.y + step.y)
        if !dryFloor(world, next, lakes: lakes) {
          continue
        }
        var touch = 0
        for around in steps {
          let side = CellPoint(x: next.x + around.x, y: next.y + around.y)
          if lakes.contains(side) {
            touch += 1
          }
        }
        if touch >= 2 {
          return true
        }
      }
    }
    return false
  }

  private func dryFloor(_ world: FloorWorld, _ point: CellPoint, lakes: [CellPoint]) -> Bool {
    world.walk.maze.span.contains(point) && world.walk.maze.tile(at: point) == .floor
      && !lakes.contains(point)
  }

  private func allOpen(_ field: FloorFixtureField) -> Bool {
    for fixture in field.fixtures {
      switch fixture.phase {
      case .open:
        break
      case .sealed, .bursting:
        return false
      }
    }
    return true
  }
}
