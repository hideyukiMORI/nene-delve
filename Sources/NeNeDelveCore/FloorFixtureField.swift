public struct FloorFixtureField: Equatable, Sendable {
  public struct BurstMark: Equatable, Sendable {
    public let point: CellPoint
    public let age: Int
  }

  /// これより少ない床には置かない。生成器の乱数とは別の列を使う。
  public static let minimumSpots = 24

  /// 石を含む水面の上限。広い階でも部屋を埋め尽くさない。
  static let pondCap = 11

  public let fixtures: [FloorFixture]
  public let wade: Int
  public let hold: Int
  public let prowlers: [FloorProwler]

  public init(
    fixtures: [FloorFixture], wade: Int, hold: Int = 0, prowlers: [FloorProwler] = []
  ) {
    self.fixtures = fixtures
    self.wade = wade
    self.hold = hold
    self.prowlers = prowlers
  }

  public static func placed(in maze: Maze, seed: Seed, depth: Int) -> FloorFixtureField {
    let spots = candidates(maze)
    if spots.count < minimumSpots {
      return FloorFixtureField(fixtures: [], wade: 0)
    }
    let (roll, rng) = SplitMix64(seed: seed).next()
    let count = min(spots.count, 1 + Int(roll % 3))
    let chests = choose(spots, count: count, rng: rng)
    let water = pond(maze, spots: spots, taken: chests.used, rng: chests.rng)
    let taken = chests.used + water.used
    let beasts = lurking(spots, taken: taken, rng: water.rng, depth: depth)
    let traps = pits(spots, taken: taken + beasts.used, rng: beasts.rng)
    return FloorFixtureField(
      fixtures: chests.fixtures + water.fixtures + traps.fixtures, wade: 0,
      prowlers: beasts.prowlers
    )
  }

  public var holdsSealed: Bool {
    for fixture in fixtures {
      switch fixture.phase {
      case .sealed, .bursting:
        return true
      case .open:
        break
      }
    }
    return false
  }

  public func sealed(at point: CellPoint) -> Bool {
    for fixture in fixtures where fixture.point == point {
      switch fixture.kind {
      case .chest:
        switch fixture.phase {
        case .sealed:
          return true
        case .bursting, .open:
          return false
        }
      case .lake, .pit:
        return false
      }
    }
    return false
  }

  public func pit(at point: CellPoint) -> Bool {
    for fixture in fixtures where fixture.point == point {
      switch fixture.kind {
      case .pit:
        switch fixture.phase {
        case .sealed:
          return true
        case .bursting, .open:
          return false
        }
      case .chest, .lake:
        return false
      }
    }
    return false
  }

  public func nearestSealed(to origin: CellPoint) -> CellPoint? {
    var best: CellPoint?
    var bestDistance = 0
    for fixture in fixtures {
      if let distance = sealedDistance(fixture, origin: origin) {
        if best == nil || distance < bestDistance {
          best = fixture.point
          bestDistance = distance
        }
      }
    }
    return best
  }

  public func burstMark() -> BurstMark? {
    for fixture in fixtures {
      switch fixture.phase {
      case .bursting(let age):
        return BurstMark(point: fixture.point, age: age)
      case .sealed, .open:
        break
      }
    }
    return nil
  }

  public func lake(at point: CellPoint) -> Bool {
    for fixture in fixtures where fixture.point == point {
      switch fixture.kind {
      case .lake:
        return true
      case .chest, .pit:
        return false
      }
    }
    return false
  }

  public func lakePoints() -> [CellPoint] {
    var points: [CellPoint] = []
    for fixture in fixtures {
      switch fixture.kind {
      case .lake:
        points.append(fixture.point)
      case .chest, .pit:
        break
      }
    }
    return points
  }

  public func entered(_ point: CellPoint) -> FloorFixtureField {
    if lake(at: point) {
      return copied(wade: FloorFixture.wadeSpan)
    }
    return self
  }

  public func pausing() -> FloorFixtureField? {
    if wade <= 0 {
      return nil
    }
    return copied(wade: wade - 1)
  }

  public func hunted(_ runner: CellPoint, in maze: Maze) -> FloorFixtureField {
    let moved = prowlers.map { step in
      let next = step.hunted(in: maze, runner: runner)
      if sealed(at: next.point) {
        return step
      }
      return next
    }
    return copied(prowlers: moved)
  }

  public func encountered(_ runner: CellPoint) -> FloorFixtureField {
    if hold > 0 {
      return self
    }
    var caught = false
    let next = prowlers.map { step -> FloorProwler in
      if step.near(runner) && blinking(step) {
        caught = true
        return step.begun()
      }
      return step
    }
    if !caught {
      return copied(prowlers: next)
    }
    return copied(hold: FloorProwler.fightSpan, prowlers: next)
  }

  public func performing(in maze: Maze, runner: CellPoint) -> FloorFixtureField? {
    if hold <= 0 {
      return nil
    }
    let aged = prowlers.map { $0.aged(in: maze, runner: runner) }.filter { !finished($0) }
    return copied(hold: renewed(aged), prowlers: aged)
  }

  public func prowler(at point: CellPoint) -> FloorProwler? {
    for step in prowlers where step.point == point {
      switch step.mood {
      case .gone:
        break
      case .blink, .fight, .flee:
        return step
      }
    }
    return nil
  }

  public func fighting() -> FloorProwler? {
    for step in prowlers {
      switch step.mood {
      case .fight:
        return step
      case .blink, .flee, .gone:
        break
      }
    }
    return nil
  }

  public func spring(at point: CellPoint) -> FloorFixtureField {
    copied(fixtures: fixtures.map { openedPit($0, at: point) }, wade: FloorFixture.snareSpan)
  }

  public func cleared(_ foe: FloorProwler) -> FloorFixtureField {
    var left: [FloorProwler] = []
    for step in prowlers where step.point != foe.point {
      left.append(step)
    }
    return copied(hold: 0, prowlers: left)
  }

  public func holding(_ foe: FloorProwler, span: Int) -> FloorFixtureField {
    copied(hold: span, prowlers: [foe])
  }

  public func replacing(_ foe: FloorProwler) -> FloorFixtureField {
    let next = prowlers.map { step in
      if step.point == foe.point {
        return foe
      }
      return step
    }
    return copied(prowlers: next)
  }

  public func beginBurst(at point: CellPoint) -> FloorFixtureField {
    copied(fixtures: fixtures.map { retimed($0, at: point) })
  }

  public func ageBurst() -> FloorFixtureField {
    copied(fixtures: fixtures.map { aged($0) })
  }

  private func copied(
    fixtures: [FloorFixture]? = nil, wade: Int? = nil, hold: Int? = nil,
    prowlers: [FloorProwler]? = nil
  ) -> FloorFixtureField {
    FloorFixtureField(
      fixtures: fixtures ?? self.fixtures,
      wade: wade ?? self.wade,
      hold: hold ?? self.hold,
      prowlers: prowlers ?? self.prowlers
    )
  }

  private func blinking(_ step: FloorProwler) -> Bool {
    switch step.mood {
    case .blink:
      true
    case .fight, .flee, .gone:
      false
    }
  }

  private func finished(_ step: FloorProwler) -> Bool {
    switch step.mood {
    case .gone:
      true
    case .blink, .fight, .flee:
      false
    }
  }

  private func renewed(_ aged: [FloorProwler]) -> Int {
    for step in aged {
      switch step.mood {
      case .flee(0):
        return FloorProwler.fleeSpan
      case .blink, .fight, .flee, .gone:
        break
      }
    }
    return hold - 1
  }

  private func sealedDistance(_ fixture: FloorFixture, origin: CellPoint) -> Int? {
    switch fixture.kind {
    case .chest:
      switch fixture.phase {
      case .sealed:
        return abs(fixture.point.x - origin.x) + abs(fixture.point.y - origin.y)
      case .bursting, .open:
        return nil
      }
    case .lake, .pit:
      return nil
    }
  }

  private func retimed(_ fixture: FloorFixture, at point: CellPoint) -> FloorFixture {
    if fixture.point != point {
      return fixture
    }
    switch fixture.phase {
    case .sealed:
      return FloorFixture(point: fixture.point, kind: fixture.kind, phase: .bursting(0))
    case .bursting, .open:
      return fixture
    }
  }

  private func openedPit(_ fixture: FloorFixture, at point: CellPoint) -> FloorFixture {
    if fixture.point != point {
      return fixture
    }
    switch fixture.kind {
    case .pit:
      return FloorFixture(point: fixture.point, kind: fixture.kind, phase: .open)
    case .chest, .lake:
      return fixture
    }
  }

  private func aged(_ fixture: FloorFixture) -> FloorFixture {
    switch fixture.phase {
    case .bursting(let age):
      let next = age + 1
      if next >= FloorFixture.burstSpan {
        return FloorFixture(point: fixture.point, kind: fixture.kind, phase: .open)
      }
      return FloorFixture(point: fixture.point, kind: fixture.kind, phase: .bursting(next))
    case .sealed, .open:
      return fixture
    }
  }

  private static func candidates(_ maze: Maze) -> [CellPoint] {
    var spots: [CellPoint] = []
    var row = 0
    while row < maze.span.height {
      var column = 0
      while column < maze.span.width {
        let point = CellPoint(x: column, y: row)
        if maze.tile(at: point) == .floor && point != maze.start && point != maze.stairs {
          spots.append(point)
        }
        column += 1
      }
      row += 1
    }
    return spots
  }

  private struct Pick {
    let fixtures: [FloorFixture]
    let used: [CellPoint]
    let rng: SplitMix64
  }

  private static func choose(_ spots: [CellPoint], count: Int, rng: SplitMix64) -> Pick {
    var pool = spots
    var generator = rng
    var chosen: [FloorFixture] = []
    var used: [CellPoint] = []
    var index = 0
    while index < count {
      let (value, next) = generator.next()
      generator = next
      let pick = index + Int(value % UInt64(pool.count - index))
      let point = pool[pick]
      pool[pick] = pool[index]
      pool[index] = point
      chosen.append(FloorFixture(point: point, kind: .chest, phase: .sealed))
      used.append(point)
      index += 1
    }
    return Pick(fixtures: chosen, used: used, rng: generator)
  }

  private static func pond(
    _ maze: Maze, spots: [CellPoint], taken: [CellPoint], rng: SplitMix64
  ) -> Pick {
    let (roll, next) = rng.next()
    if !roll.isMultiple(of: 2) {
      return Pick(fixtures: [], used: [], rng: next)
    }
    let open = unused(spots, taken: taken)
    if open.isEmpty {
      return Pick(fixtures: [], used: [], rng: next)
    }
    let (indexRoll, after) = next.next()
    let origin = open[Int(indexRoll % UInt64(open.count))]
    var water = flood(maze, from: origin, blocked: taken + [maze.start])
    if water.count < 5 {
      return Pick(fixtures: [], used: [], rng: after)
    }
    let stone = dryStone(water)
    water.removeAll { $0 == stone }
    let lakes = water.map { FloorFixture(point: $0, kind: .lake, phase: .open) }
    return Pick(fixtures: lakes, used: water, rng: after)
  }

  private struct Lurkers {
    let prowlers: [FloorProwler]
    let used: [CellPoint]
    let rng: SplitMix64
  }

  private struct Plant {
    let beast: FloorProwler
    let rng: SplitMix64
  }

  /// 広い階のおよそ 5 分の 4。空いていればもう 1 体。およそ 3 分の 2 は追いかけてくる。
  private static func lurking(
    _ spots: [CellPoint], taken: [CellPoint], rng: SplitMix64, depth: Int
  ) -> Lurkers {
    let (roll, next) = rng.next()
    if roll.isMultiple(of: 5) {
      return Lurkers(prowlers: [], used: [], rng: next)
    }
    let open = unused(spots, taken: taken)
    guard let first = plant(open, rng: next, depth: depth) else {
      return Lurkers(prowlers: [], used: [], rng: next)
    }
    return company(open, first: first, depth: depth)
  }

  private static func company(_ open: [CellPoint], first: Plant, depth: Int) -> Lurkers {
    let (extra, rest) = first.rng.next()
    var prowlers = [first.beast]
    var used = [first.beast.point]
    if !extra.isMultiple(of: 2) {
      return Lurkers(prowlers: prowlers, used: used, rng: rest)
    }
    guard let second = plant(unused(open, taken: used), rng: rest, depth: depth) else {
      return Lurkers(prowlers: prowlers, used: used, rng: rest)
    }
    prowlers.append(second.beast)
    used.append(second.beast.point)
    return Lurkers(prowlers: prowlers, used: used, rng: second.rng)
  }

  private static func plant(_ open: [CellPoint], rng: SplitMix64, depth: Int) -> Plant? {
    if open.isEmpty {
      return nil
    }
    let (indexRoll, after) = rng.next()
    let origin = open[Int(indexRoll % UInt64(open.count))]
    let (chaseRoll, rest) = after.next()
    let chases = !chaseRoll.isMultiple(of: 3)
    let life = DelverVitals.foeLife(depth: depth, chases: chases)
    let beast = FloorProwler(point: origin, chases: chases, mood: .blink, life: life)
    return Plant(beast: beast, rng: rest)
  }

  private static func pits(_ spots: [CellPoint], taken: [CellPoint], rng: SplitMix64) -> Pick {
    let (roll, next) = rng.next()
    if roll % 4 != 0 {
      return Pick(fixtures: [], used: [], rng: next)
    }
    let open = unused(spots, taken: taken)
    if open.isEmpty {
      return Pick(fixtures: [], used: [], rng: next)
    }
    let (indexRoll, after) = next.next()
    let origin = open[Int(indexRoll % UInt64(open.count))]
    let trap = FloorFixture(point: origin, kind: .pit, phase: .sealed)
    return Pick(fixtures: [trap], used: [origin], rng: after)
  }

  /// つながった水面のうち、隣の水面が一番多いマスを石にする。同点は掘り始め側。
  private static func dryStone(_ cells: [CellPoint]) -> CellPoint {
    var best = cells[0]
    var bestTouch = -1
    for cell in cells {
      let touch = neighbors(cell, cells)
      if touch > bestTouch {
        best = cell
        bestTouch = touch
      }
    }
    return best
  }

  private static func neighbors(_ cell: CellPoint, _ cells: [CellPoint]) -> Int {
    var count = 0
    for direction in Direction.cardinal {
      let next = CellPoint(x: cell.x + direction.stepX, y: cell.y + direction.stepY)
      if cells.contains(next) {
        count += 1
      }
    }
    return count
  }

  private static func unused(_ spots: [CellPoint], taken: [CellPoint]) -> [CellPoint] {
    var open: [CellPoint] = []
    for spot in spots where !taken.contains(spot) {
      open.append(spot)
    }
    return open
  }

  private static func flood(_ maze: Maze, from origin: CellPoint, blocked: [CellPoint])
    -> [CellPoint]
  {
    var found = [origin]
    var head = 0
    while head < found.count && found.count < pondCap {
      let current = found[head]
      head += 1
      spread(maze, from: current, blocked: blocked, found: &found)
    }
    return found
  }

  private static func spread(
    _ maze: Maze, from current: CellPoint, blocked: [CellPoint], found: inout [CellPoint]
  ) {
    for direction in Direction.cardinal {
      if found.count >= pondCap {
        return
      }
      let next = CellPoint(x: current.x + direction.stepX, y: current.y + direction.stepY)
      if accepts(maze, next, blocked: blocked, found: found) {
        found.append(next)
      }
    }
  }

  private static func accepts(
    _ maze: Maze, _ next: CellPoint, blocked: [CellPoint], found: [CellPoint]
  ) -> Bool {
    if !maze.span.contains(next) || found.contains(next) || blocked.contains(next) {
      return false
    }
    switch maze.tile(at: next) {
    case .floor:
      return true
    case .wall, .stairs:
      return false
    }
  }
}
