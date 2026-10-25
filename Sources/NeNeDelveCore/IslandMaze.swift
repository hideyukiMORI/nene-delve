/// 壁の海に島を置き、橋でつなぐ。湖の仕掛けは使わない。
enum IslandMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let islands = kept(centers(span), seed: seed)
    var index = 0
    while index < islands.count {
      grow(&tiles, span: span, at: islands[index])
      if index > 0 {
        MazeInk.line(&tiles, span: span, from: islands[index - 1], to: islands[index])
      }
      index += 1
    }
    return MazeStamp.seal(tiles: tiles, span: span, kind: .islands)
  }

  private static func centers(_ span: GridSpan) -> [CellPoint] {
    var found: [CellPoint] = []
    var y = 2
    while y < span.height - 2 {
      var x = 2
      while x < span.width - 2 {
        found.append(CellPoint(x: x, y: y))
        x += 4
      }
      y += 4
    }
    if found.isEmpty {
      found.append(CellPoint(x: span.width / 2, y: span.height / 2))
    }
    return found
  }

  private static func kept(_ centers: [CellPoint], seed: Seed) -> [CellPoint] {
    if centers.count <= 2 {
      return centers
    }
    var chosen = [centers[0]]
    var rng = SplitMix64(seed: seed)
    var index = 1
    while index < centers.count - 1 {
      let roll = rng.next()
      rng = roll.generator
      if !roll.value.isMultiple(of: 3) {
        chosen.append(centers[index])
      }
      index += 1
    }
    chosen.append(centers[centers.count - 1])
    return chosen
  }

  private static func grow(_ tiles: inout [Tile], span: GridSpan, at point: CellPoint) {
    MazeInk.floor(&tiles, span: span, at: point)
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      MazeInk.floor(&tiles, span: span, at: next)
    }
  }
}
