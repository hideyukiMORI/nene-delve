public struct FloorProwler: Equatable, Sendable {
  public enum Mood: Equatable, Sendable {
    case blink
    case fight(Int)
    case flee(Int)
    case gone
  }

  public static let fightSpan = 6
  public static let fleeSpan = 4

  public let point: CellPoint
  public let chases: Bool
  public let mood: Mood
  public let life: Int
  public let boss: Bool

  /// 宝箱から出た個体。追わず、6 拍ではボスのように残らない。
  public let mimic: Bool

  /// 配置時は階の体力を渡す。省略した個体は 1 戦では倒れない。
  public init(point: CellPoint, chases: Bool, mood: Mood, life: Int = 48) {
    self.point = point
    self.chases = chases
    self.mood = mood
    self.life = life
    self.boss = false
    self.mimic = false
  }

  /// 大部屋のボスは追わず、6 拍では退かない。
  public init(bossAt point: CellPoint, mood: Mood, life: Int) {
    self.point = point
    self.chases = false
    self.mood = mood
    self.life = life
    self.boss = true
    self.mimic = false
  }

  /// 宝箱の隣へ飛び出す。体力は追わない敵と同じ式を渡す。
  public init(mimicAt point: CellPoint, mood: Mood, life: Int) {
    self.point = point
    self.chases = false
    self.mood = mood
    self.life = life
    self.boss = false
    self.mimic = true
  }

  func near(_ runner: CellPoint) -> Bool {
    abs(point.x - runner.x) + abs(point.y - runner.y) <= 1
  }

  func begun() -> FloorProwler {
    copied(point: point, mood: .fight(0), life: life)
  }

  func wounded(_ damage: Int) -> FloorProwler {
    copied(point: point, mood: mood, life: life - max(damage, 0))
  }

  func fleeing() -> FloorProwler {
    copied(point: point, mood: .flee(0), life: life)
  }

  func aged(in maze: Maze, runner: CellPoint) -> FloorProwler {
    switch mood {
    case .blink, .gone:
      self
    case .fight(let age):
      struck(age)
    case .flee(let age):
      retreated(age, in: maze, runner: runner)
    }
  }

  func hunted(in maze: Maze, runner: CellPoint) -> FloorProwler {
    switch mood {
    case .fight, .flee, .gone:
      return self
    case .blink:
      break
    }
    if !chases || near(runner) {
      return self
    }
    guard let step = FloorRoute.firstStep(maze, from: point, to: runner) else {
      return self
    }
    if step == runner {
      return self
    }
    return copied(point: step, mood: mood, life: life)
  }

  private func copied(point: CellPoint, mood: Mood, life: Int) -> FloorProwler {
    if boss {
      return FloorProwler(bossAt: point, mood: mood, life: life)
    }
    if mimic {
      return FloorProwler(mimicAt: point, mood: mood, life: life)
    }
    return FloorProwler(point: point, chases: chases, mood: mood, life: life)
  }

  private func struck(_ age: Int) -> FloorProwler {
    let next = age + 1
    if next < Self.fightSpan || boss {
      return copied(point: point, mood: .fight(next), life: life)
    }
    if chases {
      return copied(point: point, mood: .flee(0), life: life)
    }
    return copied(point: point, mood: .gone, life: life)
  }

  private func retreated(_ age: Int, in maze: Maze, runner: CellPoint) -> FloorProwler {
    let next = age + 1
    if next >= Self.fleeSpan {
      return copied(point: point, mood: .gone, life: life)
    }
    let away = further(in: maze, runner: runner)
    return copied(point: away, mood: .flee(next), life: life)
  }

  private func further(in maze: Maze, runner: CellPoint) -> CellPoint {
    var best = point
    var bestDistance = abs(point.x - runner.x) + abs(point.y - runner.y)
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      let distance = abs(next.x - runner.x) + abs(next.y - runner.y)
      if distance > bestDistance && openFloor(maze, next) {
        best = next
        bestDistance = distance
      }
    }
    return best
  }

  private func openFloor(_ maze: Maze, _ point: CellPoint) -> Bool {
    if !maze.span.contains(point) {
      return false
    }
    switch maze.tile(at: point) {
    case .floor:
      return true
    case .wall, .stairs:
      return false
    }
  }
}
