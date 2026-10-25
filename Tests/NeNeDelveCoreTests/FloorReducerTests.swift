import Testing

@testable import NeNeDelveCore

struct FloorReducerTests {
  @Test func descentDeepensByOneAndRepeats() {
    let span = GridSpan(width: 11, height: 9)
    let launch = Seed(raw: 5)
    let first = descend(launch, span: span)
    let again = descend(launch, span: span)
    #expect(first?.course.floor.depth == 2)
    #expect(first == again)
    #expect(first?.course.launchSeed == launch)
    #expect(first?.walk.maze != opened(launch, span: span))
  }

  @Test func floorOneUsesTheLaunchSeed() {
    let launch = Seed(raw: 19)
    #expect(launch.forFloor(.first) == launch)
    #expect(launch.forFloor(.first.deeper()) != launch)
    #expect(launch.forFloor(.first.deeper()) == launch.forFloor(.first.deeper()))
  }

  @Test func aDropSkipsTheWaitAndOpensTheSameNextFloor() {
    let span = GridSpan(width: 11, height: 9)
    let launch = Seed(raw: 5)
    guard case .world(let world) = FloorReducer.begin(launchSeed: launch, span: span) else {
      Issue.record("the span did not open")
      return
    }
    guard case .descended(let stood) = FloorReducer.tick(waiting(world)) else {
      Issue.record("the drop did not descend")
      return
    }
    #expect(stood.walk.explorer.position == world.walk.explorer.position)
    #expect(stood.walk.steps == world.walk.steps)
    #expect(stood.walk.maze == world.walk.maze)
    guard case .ready(let next) = FloorReducer.nextFloor(stood) else {
      Issue.record("the next floor did not open")
      return
    }
    guard case .ready(let same) = FloorReducer.nextFloor(world) else {
      Issue.record("the stair path did not open")
      return
    }
    #expect(next == same)
    #expect(next.course.floor.depth == 2)
    #expect(next.aim == .explore)
  }

  private func waiting(_ world: FloorWorld) -> FloorWorld {
    let field = FloorFixtureField(
      fixtures: world.fixtures.fixtures, wade: world.fixtures.wade, hold: 6,
      prowlers: world.fixtures.prowlers)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: field, aim: .drop)
  }

  private func opened(_ seed: Seed, span: GridSpan) -> Maze? {
    guard case .world(let world) = FloorReducer.begin(launchSeed: seed, span: span) else {
      return nil
    }
    return world.walk.maze
  }

  private func descend(_ seed: Seed, span: GridSpan) -> FloorWorld? {
    guard case .world(var world) = FloorReducer.begin(launchSeed: seed, span: span) else {
      return nil
    }
    let bound = world.walk.maze.span.count * 2
    var steps = 0
    while steps <= bound {
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended(let onStairs):
        guard case .ready(let next) = FloorReducer.nextFloor(onStairs) else {
          return nil
        }
        return next
      case .ascended, .stuck:
        return nil
      }
      steps += 1
    }
    return nil
  }
}
