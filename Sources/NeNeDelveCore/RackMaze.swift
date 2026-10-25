/// ラックの列。横の通りは床であり、湖ではない。
enum RackMaze {
  static func maze(seed _: Seed, span: GridSpan) -> Maze {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var y = 1
    while y < span.height - 1 {
      aisle(&tiles, span: span, y: y)
      y += 1
    }
    return MazeStamp.seal(tiles: tiles, span: span, kind: .racks)
  }

  private static func aisle(_ tiles: inout [Tile], span: GridSpan, y: Int) {
    var x = 1
    while x < span.width - 1 {
      if x % 4 != 2 || y % 4 == 2 {
        MazeInk.floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      }
      x += 1
    }
  }
}
