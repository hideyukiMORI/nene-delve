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
    #expect(world.fixtures.fixtures.count >= 1)
    #expect(world.fixtures.fixtures.count <= 3)
    for fixture in world.fixtures.fixtures {
      #expect(fixture.kind == .chest)
      #expect(fixture.phase == .sealed)
      #expect(world.walk.maze.tile(at: fixture.point) == .floor)
      #expect(fixture.point != world.walk.maze.start)
      #expect(fixture.point != world.walk.maze.stairs)
    }
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
