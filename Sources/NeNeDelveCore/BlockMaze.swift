/// 街区。4 升ごとの大通りと、種で決まる扉。回路より壁が多い。
enum BlockMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    streets(&tiles, span: span)
    doors(&tiles, span: span, seed: seed)
    return MazeStamp.seal(tiles: tiles, span: span, kind: .blocks)
  }

  private static func streets(_ tiles: inout [Tile], span: GridSpan) {
    var y = 1
    while y < span.height - 1 {
      street(&tiles, span: span, y: y)
      y += 1
    }
  }

  private static func street(_ tiles: inout [Tile], span: GridSpan, y: Int) {
    var x = 1
    while x < span.width - 1 {
      let point = CellPoint(x: x, y: y)
      if avenue(point) {
        MazeInk.floor(&tiles, span: span, at: point)
      }
      x += 1
    }
  }

  private static func doors(_ tiles: inout [Tile], span: GridSpan, seed: Seed) {
    var rng = SplitMix64(seed: seed)
    var y = 1
    while y < span.height - 1 {
      rng = doorRow(&tiles, span: span, y: y, rng: rng)
      y += 1
    }
  }

  private static func doorRow(
    _ tiles: inout [Tile], span: GridSpan, y: Int, rng: SplitMix64
  ) -> SplitMix64 {
    var rng = rng
    var x = 1
    while x < span.width - 1 {
      rng = consider(&tiles, span: span, at: CellPoint(x: x, y: y), rng: rng)
      x += 1
    }
    return rng
  }

  private static func consider(
    _ tiles: inout [Tile], span: GridSpan, at point: CellPoint, rng: SplitMix64
  ) -> SplitMix64 {
    if avenue(point) {
      return rng
    }
    let roll = rng.next()
    if roll.value.isMultiple(of: 7) && beside(point, span: span) {
      MazeInk.floor(&tiles, span: span, at: point)
    }
    return roll.generator
  }

  private static func beside(_ point: CellPoint, span: GridSpan) -> Bool {
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      if span.contains(next) && avenue(next) {
        return true
      }
    }
    return false
  }

  private static func avenue(_ point: CellPoint) -> Bool {
    point.x % 4 == 1 || point.y % 4 == 1
  }
}
