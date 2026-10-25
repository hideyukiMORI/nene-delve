/// 回路。3 升ごとの配線と、交差点のチップ。ワープは足さない。
enum CircuitMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    traces(&tiles, span: span)
    chips(&tiles, span: span, seed: seed)
    return MazeStamp.seal(tiles: tiles, span: span, kind: .circuit)
  }

  private static func traces(_ tiles: inout [Tile], span: GridSpan) {
    var y = 1
    while y < span.height - 1 {
      trace(&tiles, span: span, y: y)
      y += 1
    }
  }

  private static func trace(_ tiles: inout [Tile], span: GridSpan, y: Int) {
    var x = 1
    while x < span.width - 1 {
      if x % 3 == 1 || y % 3 == 1 {
        MazeInk.floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      }
      x += 1
    }
  }

  private static func chips(_ tiles: inout [Tile], span: GridSpan, seed: Seed) {
    var rng = SplitMix64(seed: seed)
    var y = 1
    while y < span.height - 1 {
      rng = chipRow(&tiles, span: span, y: y, rng: rng)
      y += 3
    }
  }

  private static func chipRow(
    _ tiles: inout [Tile], span: GridSpan, y: Int, rng: SplitMix64
  ) -> SplitMix64 {
    var rng = rng
    var x = 1
    while x < span.width - 1 {
      rng = maybe(&tiles, span: span, at: CellPoint(x: x, y: y), rng: rng)
      x += 3
    }
    return rng
  }

  private static func maybe(
    _ tiles: inout [Tile], span: GridSpan, at point: CellPoint, rng: SplitMix64
  ) -> SplitMix64 {
    let roll = rng.next()
    if roll.value.isMultiple(of: 2) {
      block(&tiles, span: span, at: point)
    }
    return roll.generator
  }

  private static func block(_ tiles: inout [Tile], span: GridSpan, at point: CellPoint) {
    var y = point.y - 1
    while y <= point.y + 1 {
      blockRow(&tiles, span: span, y: y, point: point)
      y += 1
    }
  }

  private static func blockRow(_ tiles: inout [Tile], span: GridSpan, y: Int, point: CellPoint) {
    var x = point.x - 1
    while x <= point.x + 1 {
      MazeInk.floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      x += 1
    }
  }
}
