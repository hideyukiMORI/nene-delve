/// 置いた宝箱のおよそ 3 分の 1 を、位置を変えずに噛みつかせる。
enum ChestMimic {
  static func disguise(_ chests: [FloorFixture], rng: SplitMix64) -> [FloorFixture] {
    var generator = rng
    var marked: [FloorFixture] = []
    for chest in chests {
      let (roll, next) = generator.next()
      generator = next
      marked.append(tagged(chest, mimic: roll.isMultiple(of: 3)))
    }
    return marked
  }

  /// 北、東、南、西の順で、空いている床。無ければ宝箱の升。
  static func stand(at point: CellPoint, in maze: Maze, prowlers: [FloorProwler]) -> CellPoint {
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      if open(maze, next, prowlers: prowlers) {
        return next
      }
    }
    return point
  }

  private static func tagged(_ chest: FloorFixture, mimic: Bool) -> FloorFixture {
    FloorFixture(point: chest.point, kind: chest.kind, phase: chest.phase, mimic: mimic)
  }

  private static func open(_ maze: Maze, _ point: CellPoint, prowlers: [FloorProwler]) -> Bool {
    if !maze.span.contains(point) || occupied(point, prowlers: prowlers) {
      return false
    }
    switch maze.tile(at: point) {
    case .floor:
      return true
    case .wall, .stairs:
      return false
    }
  }

  private static func occupied(_ point: CellPoint, prowlers: [FloorProwler]) -> Bool {
    for step in prowlers where step.point == point {
      switch step.mood {
      case .gone:
        break
      case .blink, .fight, .flee:
        return true
      }
    }
    return false
  }
}
