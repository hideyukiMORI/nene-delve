import Testing

@testable import NeNeDelveCore

struct ChestMimicTests {
  @Test func someChestsBiteAndTheRestStayLoot() {
    var biting = 0
    var quiet = 0
    let span = GridSpan(width: 41, height: 21)
    for raw in 1...40 {
      guard case .world(let world) = FloorReducer.begin(launchSeed: Seed(raw: UInt64(raw)), span: span)
      else {
        Issue.record("expected a floor")
        return
      }
      let count = chests(world)
      #expect(count.chests >= 1)
      #expect(count.chests <= 3)
      #expect(count.mimics <= count.chests)
      #expect(othersStayLoot(world))
      if count.mimics > 0 {
        biting += 1
      } else {
        quiet += 1
      }
    }
    #expect(biting > 0)
    #expect(quiet > 0)
  }

  @Test func aBiteOpensTheChestAndSpringsBeside() {
    guard let world = baited() else {
      Issue.record("expected a corridor")
      return
    }
    guard case .running(let next) = FloorReducer.tick(world) else {
      Issue.record("the mimic should stay on this floor")
      return
    }
    #expect(next.course.delver.vitals.experience == 0)
    #expect(next.course.delver.line.moment == .mimic)
    #expect(next.course.delver.line.note == 0)
    #expect(next.fixtures.burstMark() == nil)
    #expect(!next.fixtures.sealed(at: CellPoint(x: 2, y: 1)))
    #expect(next.fixtures.hold == FloorProwler.fightSpan)
    guard let foe = next.fixtures.prowlers.first else {
      Issue.record("the mimic should spring")
      return
    }
    #expect(next.fixtures.prowlers.count == 1)
    #expect(foe.mimic)
    #expect(!foe.chases)
    #expect(!foe.boss)
    #expect(foe.point == CellPoint(x: 1, y: 1))
    #expect(foe.life == DelverVitals.foeLife(depth: 1, chases: false))
    guard case .fight(0) = foe.mood else {
      Issue.record("the mimic should already be fighting")
      return
    }
  }

  @Test func theNextBeatNamesTheBite() {
    guard let world = baited(), case .running(let sprung) = FloorReducer.tick(world) else {
      Issue.record("the mimic should stay on this floor")
      return
    }
    guard case .running(let next) = FloorReducer.tick(sprung) else {
      Issue.record("the bout should stay on this floor")
      return
    }
    let life = DelverVitals.foeLife(depth: 1, chases: false)
    #expect(next.course.delver.line.moment == .mimic)
    #expect(next.course.delver.line.note == DelverVitals.foeBlow(depth: 1, chases: false))
    #expect(next.course.delver.vitals.experience == 0)
    guard let foe = next.fixtures.prowlers.first else {
      Issue.record("the mimic should still be fighting")
      return
    }
    #expect(foe.life < life)
    #expect(foe.mimic)
  }

  @Test func aHighLifeMimicLeavesAtTheLastBeat() {
    guard let world = corridor() else {
      Issue.record("expected a corridor")
      return
    }
    let foe = FloorProwler(mimicAt: CellPoint(x: 1, y: 1), mood: .fight(5), life: 80)
    let field = FloorFixtureField(fixtures: [], wade: 0, hold: 1, prowlers: [foe])
    let fighting = FloorWorld(
      course: world.course, walk: world.walk, fixtures: field, aim: world.aim)
    guard case .running(let next) = FloorReducer.tick(fighting) else {
      Issue.record("the bout should stay on this floor")
      return
    }
    #expect(next.fixtures.prowlers.isEmpty)
    #expect(next.fixtures.hold == 0)
    #expect(next.course.delver.line.moment == .drove)
    #expect(next.course.delver.vitals.experience == DelverVitals.driveExperience(depth: 1))
  }

  private func chests(_ world: FloorWorld) -> (chests: Int, mimics: Int) {
    var chests = 0
    var mimics = 0
    for fixture in world.fixtures.fixtures {
      switch fixture.kind {
      case .chest:
        chests += 1
        if fixture.mimic {
          mimics += 1
          #expect(fixture.phase == .sealed)
        }
      case .lake, .pit, .warp:
        break
      }
    }
    return (chests, mimics)
  }

  private func othersStayLoot(_ world: FloorWorld) -> Bool {
    for fixture in world.fixtures.fixtures {
      switch fixture.kind {
      case .chest:
        break
      case .lake, .pit, .warp:
        if fixture.mimic {
          return false
        }
      }
    }
    return true
  }

  private func baited() -> FloorWorld? {
    guard let world = corridor() else {
      return nil
    }
    let chest = FloorFixture(
      point: CellPoint(x: 2, y: 1), kind: .chest, phase: .sealed, mimic: true)
    let field = FloorFixtureField(fixtures: [chest], wade: 0)
    return FloorWorld(course: world.course, walk: world.walk, fixtures: field, aim: world.aim)
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
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .rooms)
    let pin = DelverLine.QuipPin(seed: Seed(raw: 1), floor: .first, place: start)
    let course = FloorCourse(
      launchSeed: Seed(raw: 1), floor: .first, pace: .explore, delver: Delver.fresh(pin))
    let walk = FloorWalk(
      maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0)
    return FloorWorld(
      course: course, walk: walk, fixtures: FloorFixtureField(fixtures: [], wade: 0), aim: .explore)
  }
}
