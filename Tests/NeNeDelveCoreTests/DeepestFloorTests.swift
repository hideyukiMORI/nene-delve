import Testing

@testable import NeNeDelveCore

struct DeepestFloorTests {
  @Test func theFirstFloorStartsAtOne() {
    guard
      case .world(let world) = FloorReducer.begin(
        launchSeed: Seed(raw: 1), span: GridSpan(width: 21, height: 15))
    else {
      Issue.record("expected a floor")
      return
    }
    #expect(world.course.delver.deepest == 1)
    #expect(world.course.floor.depth == 1)
  }

  @Test func aDirectVisitRecordsThatFloor() {
    guard
      case .world(let world) = FloorReducer.resume(
        launchSeed: Seed(raw: 1), floor: FloorIndex(depth: 10),
        span: GridSpan(width: 21, height: 15),
        pace: .explore)
    else {
      Issue.record("expected a floor")
      return
    }
    #expect(world.course.delver.deepest == 10)
  }

  @Test func descentRaisesTheRecordAndAscentKeepsIt() {
    guard
      case .world(let first) = FloorReducer.begin(
        launchSeed: Seed(raw: 4), span: GridSpan(width: 11, height: 9))
    else {
      Issue.record("expected a floor")
      return
    }
    guard case .ready(let second) = FloorReducer.nextFloor(first) else {
      Issue.record("the next floor was not ready")
      return
    }
    #expect(second.course.floor.depth == 2)
    #expect(second.course.delver.deepest == 2)
    guard case .ready(let back) = FloorReducer.previousFloor(second) else {
      Issue.record("the previous floor was not ready")
      return
    }
    #expect(back.course.floor.depth == 1)
    #expect(back.course.delver.deepest == 2)
    #expect(back.course.delver.risen == 2)
  }

  @Test func copiesKeepTheRecord() {
    let pin = DelverLine.QuipPin(seed: Seed(raw: 1), floor: .first, place: CellPoint(x: 1, y: 1))
    let kept = Delver.fresh(pin).reaching(6).noted().aged().carrying(vitals: .fresh(), line: .quiet)
      .remembering(4)
    #expect(kept.deepest == 6)
    #expect(kept.risen == 4)
    #expect(kept.reaching(2).deepest == 6)
  }
}
