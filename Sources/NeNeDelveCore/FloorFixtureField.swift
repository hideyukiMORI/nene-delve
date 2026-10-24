public struct FloorFixtureField: Equatable, Sendable {
  public struct BurstMark: Equatable, Sendable {
    public let point: CellPoint
    public let age: Int
  }

  /// これより少ない床には置かない。生成器の乱数とは別の列を使う。
  public static let minimumSpots = 24

  public let fixtures: [FloorFixture]

  public init(fixtures: [FloorFixture]) {
    self.fixtures = fixtures
  }

  public static func placed(in maze: Maze, seed: Seed) -> FloorFixtureField {
    let spots = candidates(maze)
    if spots.count < minimumSpots {
      return FloorFixtureField(fixtures: [])
    }
    let (roll, rng) = SplitMix64(seed: seed).next()
    let count = min(spots.count, 1 + Int(roll % 3))
    return FloorFixtureField(fixtures: choose(spots, count: count, rng: rng))
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

  public func beginBurst(at point: CellPoint) -> FloorFixtureField {
    FloorFixtureField(fixtures: fixtures.map { retimed($0, at: point) })
  }

  public func ageBurst() -> FloorFixtureField {
    FloorFixtureField(fixtures: fixtures.map { aged($0) })
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

  private static func choose(_ spots: [CellPoint], count: Int, rng: SplitMix64) -> [FloorFixture] {
    var pool = spots
    var generator = rng
    var chosen: [FloorFixture] = []
    var index = 0
    while index < count {
      let (value, next) = generator.next()
      generator = next
      let pick = index + Int(value % UInt64(pool.count - index))
      let point = pool[pick]
      pool[pick] = pool[index]
      pool[index] = point
      chosen.append(FloorFixture(point: point, kind: .chest, phase: .sealed))
      index += 1
    }
    return chosen
  }
}
