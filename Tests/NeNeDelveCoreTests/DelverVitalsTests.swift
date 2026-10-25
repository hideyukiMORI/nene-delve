import Testing

@testable import NeNeDelveCore

struct DelverVitalsTests {
  @Test func aLevelRestoresTheBars() {
    let tired = DelverVitals(level: 1, experience: 11, hitPoints: 1, magicPoints: 0)
    let growth = tired.gain(3)
    #expect(growth.leveled)
    #expect(growth.vitals.level == 2)
    #expect(growth.vitals.experience == 2)
    #expect(growth.vitals.hitPoints == growth.vitals.hitMax)
    #expect(growth.vitals.magicPoints == growth.vitals.magicMax)
  }

  @Test func theSamePlaceSaysTheSameLine() {
    let pin = DelverLine.QuipPin(seed: Seed(raw: 9), floor: .first, place: CellPoint(x: 2, y: 1))
    let first = DelverLine.say(.pit, pin: pin, note: 3)
    let second = DelverLine.say(.pit, pin: pin, note: 3)
    #expect(first == second)
    #expect(first.moment == .pit)
    #expect(first.note == 3)
  }

  @Test func aWeakFoeFallsAndPaysExperience() {
    guard var world = corridor() else {
      Issue.record("expected a corridor")
      return
    }
    guard let beside = neighbor(world) else {
      Issue.record("expected a neighboring floor")
      return
    }
    world = meet(world, beast: FloorProwler(point: beside, chases: false, mood: .blink, life: 1))
    guard case .running(let next) = FloorReducer.tick(world) else {
      Issue.record("the bout should stay on this floor")
      return
    }
    #expect(next.fixtures.prowlers.isEmpty)
    #expect(next.fixtures.hold == 0)
    #expect(next.course.delver.vitals.hitPoints == world.course.delver.vitals.hitPoints)
    #expect(next.course.delver.vitals.experience == DelverVitals.killExperience(depth: 1, chases: false))
    #expect(next.course.delver.line.moment == .kill)
  }

  @Test func aChestPaysExperience() {
    guard let world = stocked(.chest) else {
      Issue.record("expected a chest")
      return
    }
    guard case .running(let next) = FloorReducer.tick(world) else {
      Issue.record("the chest should stay on this floor")
      return
    }
    #expect(next.fixtures.burstMark() != nil)
    #expect(next.course.delver.vitals.experience == DelverVitals.chestExperience)
    #expect(next.course.delver.line.moment == .chest)
    #expect(next.course.delver.line.note == DelverVitals.chestExperience)
  }

  @Test func aPitHurtsAndSpeaks() {
    guard let world = stocked(.pit) else {
      Issue.record("expected a pit")
      return
    }
    let before = world.course.delver.vitals.hitPoints
    guard case .running(let next) = FloorReducer.tick(world) else {
      Issue.record("the pit should stay on this floor")
      return
    }
    let damage = DelverVitals.pitDamage(1)
    #expect(next.walk.explorer.position == CellPoint(x: 2, y: 1))
    #expect(next.course.delver.vitals.hitPoints == before - damage)
    #expect(next.course.delver.line.moment == .pit)
    #expect(next.course.delver.line.note == damage)
    #expect(next.fixtures.wade == FloorFixture.snareSpan)
    #expect(!next.fixtures.pit(at: next.walk.explorer.position))
  }

  @Test func theNextFloorKeepsTheLevel() {
    guard case .world(let world) = FloorReducer.begin(
      launchSeed: Seed(raw: 1), span: GridSpan(width: 21, height: 15))
    else {
      Issue.record("expected a floor")
      return
    }
    let seasoned = DelverVitals(level: 3, experience: 1, hitPoints: 4, magicPoints: 2)
    let carried = FloorWorld(
      course: world.course.with(delver: Delver(vitals: seasoned, line: .quiet)),
      walk: world.walk, fixtures: world.fixtures, aim: world.aim)
    guard case .ready(let next) = FloorReducer.nextFloor(carried) else {
      Issue.record("the next floor should open")
      return
    }
    #expect(next.course.floor.depth == 2)
    #expect(next.course.delver.vitals.level == 3)
    #expect(next.course.delver.vitals.hitPoints == 6)
    #expect(next.course.delver.vitals.magicPoints == 3)
    #expect(next.course.delver.line.moment == .descend)
    #expect(next.course.delver.line.note == 2)
  }

  private func stocked(_ kind: FloorFixture.Kind) -> FloorWorld? {
    guard let world = corridor() else {
      return nil
    }
    let point = CellPoint(x: 2, y: 1)
    let fixture = FloorFixture(point: point, kind: kind, phase: .sealed)
    let field = FloorFixtureField(fixtures: [fixture], wade: 0)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: field, aim: world.aim)
  }

  private func meet(_ world: FloorWorld, beast: FloorProwler) -> FloorWorld {
    let caught = FloorFixtureField(
      fixtures: world.fixtures.fixtures, wade: world.fixtures.wade, prowlers: [beast]
    ).encountered(world.walk.explorer.position)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: caught, aim: world.aim)
  }

  private func neighbor(_ world: FloorWorld) -> CellPoint? {
    let origin = world.walk.explorer.position
    let next = CellPoint(x: origin.x + 1, y: origin.y)
    if world.walk.maze.tile(at: next) == .floor {
      return next
    }
    return nil
  }

  private func corridor() -> FloorWorld? {
    let span = GridSpan(width: 5, height: 3)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    let middle = CellPoint(x: 2, y: 1)
    let stairs = CellPoint(x: 3, y: 1)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(middle)] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .rooms)
    let pin = DelverLine.QuipPin(seed: Seed(raw: 1), floor: .first, place: start)
    let course = FloorCourse(
      launchSeed: Seed(raw: 1), floor: .first, pace: .explore, delver: Delver.fresh(pin))
    let walk = FloorWalk(
      maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0)
    return FloorWorld(
      course: course, walk: walk, fixtures: FloorFixtureField(fixtures: [], wade: 0), aim: .explore)
  }
}
