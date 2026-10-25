/// 着地で壁を開ける枚数。待ちのミリ秒は実行ファイルが持つ。
public enum DigReveal {
  public static let frames = 40

  public static func maze(_ maze: Maze, frame: Int) -> Maze {
    if maze.dug.isEmpty || frame >= frames {
      return maze
    }
    let count = maze.dug.count * (frame + 1) / frames
    var open = Array(repeating: false, count: maze.span.count)
    var index = 0
    while index < count {
      mark(&open, maze.dug[index], span: maze.span)
      index += 1
    }
    mark(&open, maze.start, span: maze.span)
    return Maze(
      span: maze.span, tiles: masked(maze.tiles, open: open), plate: plate(maze), kind: maze.kind)
  }

  private static func mark(_ open: inout [Bool], _ point: CellPoint, span: GridSpan) {
    if span.contains(point) {
      open[span.offset(point)] = true
    }
  }

  private static func masked(_ tiles: [Tile], open: [Bool]) -> [Tile] {
    var next = tiles
    var offset = 0
    while offset < next.count {
      if !open[offset] {
        next[offset] = .wall
      }
      offset += 1
    }
    return next
  }

  private static func plate(_ maze: Maze) -> MazePlate {
    MazePlate(ends: maze.ends, dug: maze.dug, veil: maze.veil)
  }
}
