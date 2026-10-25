import Testing

@testable import NeNeDelveCore

struct RecoveryRouteTests {
  @Test(arguments: [
    (width: 99, height: 21),
    (width: 101, height: 35),
    (width: 103, height: 41),
    (width: 103, height: 45),
    (width: 101, height: 47),
    (width: 101, height: 49),
  ])
  func seedNineOnFloorTwoReachesTheDownStairs(width: Int, height: Int) {
    let span = GridSpan(width: width, height: height)
    guard
      case .world(var world) = FloorReducer.resume(
        launchSeed: Seed(raw: 9), floor: FloorIndex(depth: 2), span: span, pace: .explore)
    else {
      Issue.record("expected a floor")
      return
    }
    let bound = world.walk.maze.span.count * 2
    var steps = 0
    while steps <= bound + 1 {
      switch FloorReducer.tick(world) {
      case .running(let next):
        world = next
      case .descended(let stood):
        #expect(stood.walk.explorer.position == stood.walk.maze.stairs)
        #expect(stood.walk.steps <= bound)
        return
      case .ascended:
        Issue.record("\(width)x\(height) climbed")
        return
      case .stuck:
        Issue.record("\(width)x\(height) stuck at \(world.walk.explorer.position)")
        return
      }
      steps += 1
    }
    Issue.record("\(width)x\(height) did not finish")
  }
}
