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
