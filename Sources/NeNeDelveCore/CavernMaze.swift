/// 洞窟。まばらな床をならし、離れた塊は直線でつなぐ。
enum CavernMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var tiles = scattered(span, seed: seed)
    var pass = 0
    while pass < 4 {
      tiles = smoothed(tiles, span: span)
      pass += 1
    }
    return MazeStamp.seal(tiles: joined(tiles, span: span), span: span, kind: .cavern)
  }

  private static func scattered(_ span: GridSpan, seed: Seed) -> [Tile] {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var rng = SplitMix64(seed: seed)
    var y = 1
    while y < span.height - 1 {
      rng = scatter(&tiles, span: span, y: y, rng: rng)
      y += 1
    }
    return tiles
  }

  private static func scatter(
    _ tiles: inout [Tile], span: GridSpan, y: Int, rng: SplitMix64
  ) -> SplitMix64 {
    var rng = rng
    var x = 1
    while x < span.width - 1 {
      let roll = rng.next()
      rng = roll.generator
      if roll.value % 5 < 3 {
        MazeInk.floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      }
      x += 1
    }
    return rng
  }

  private static func smoothed(_ tiles: [Tile], span: GridSpan) -> [Tile] {
    var next = tiles
    var y = 1
    while y < span.height - 1 {
      smooth(&next, tiles, span: span, y: y)
      y += 1
    }
    return next
  }

  private static func smooth(_ next: inout [Tile], _ tiles: [Tile], span: GridSpan, y: Int) {
    var x = 1
    while x < span.width - 1 {
      let point = CellPoint(x: x, y: y)
      next[span.offset(point)] = born(tiles, span: span, at: point)
      x += 1
    }
  }

  private static func born(_ tiles: [Tile], span: GridSpan, at point: CellPoint) -> Tile {
    if live(tiles, span: span, at: point) >= 4 {
      return .floor
    }
    return .wall
  }

  private static func live(_ tiles: [Tile], span: GridSpan, at point: CellPoint) -> Int {
    var count = 0
    var dy = -1
    while dy <= 1 {
      count += liveRow(tiles, span: span, at: point, dy: dy)
      dy += 1
    }
    return count
  }

  private static func liveRow(_ tiles: [Tile], span: GridSpan, at point: CellPoint, dy: Int) -> Int
  {
    var count = 0
    var dx = -1
    while dx <= 1 {
      let next = CellPoint(x: point.x + dx, y: point.y + dy)
      count += aside(tiles, span: span, at: next, skip: dx == 0 && dy == 0)
      dx += 1
    }
    return count
  }

  private static func aside(
    _ tiles: [Tile], span: GridSpan, at point: CellPoint, skip: Bool
  ) -> Int {
    if skip {
      return 0
    }
    return occupied(tiles, span: span, at: point)
  }

  private static func occupied(_ tiles: [Tile], span: GridSpan, at point: CellPoint) -> Int {
    if !span.contains(point) || tiles[span.offset(point)] == .wall {
      return 0
    }
    return 1
  }

  private static func joined(_ tiles: [Tile], span: GridSpan) -> [Tile] {
    guard let origin = MazeStamp.firstOpen(tiles, span: span) else {
      return tiles
    }
    var next = tiles
    var guardPass = 0
    while guardPass < span.count {
      guardPass += 1
      let seen = MazeStamp.flood(next, span: span, from: origin)
      guard let stray = MazeStamp.firstHidden(next, span: span, seen: seen) else {
        return next
      }
      let goal = MazeStamp.nearest(seen, span: span, to: stray)
      MazeInk.line(&next, span: span, from: stray, to: goal)
    }
    return next
  }
}
