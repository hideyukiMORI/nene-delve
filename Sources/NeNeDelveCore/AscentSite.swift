/// 上り階段の位置と、この訪問で上るかどうか。
public enum AscentSite {
  public static func seeks(_ world: FloorWorld) -> Bool {
    let depth = world.course.floor.depth
    if depth <= 1 || world.walk.maze.ends.ascent == nil {
      return false
    }
    if !depth.isMultiple(of: 3) {
      return false
    }
    return depth > world.course.delver.risen
  }

  public static func point(in maze: Maze, depth: Int) -> CellPoint? {
    if depth <= 1 {
      return nil
    }
    return farthest(maze)
  }

  private static func farthest(_ maze: Maze) -> CellPoint? {
    var chosen: CellPoint?
    var best = -1
    var offset = 0
    while offset < maze.span.count {
      let cell = CellPoint(x: offset % maze.span.width, y: offset / maze.span.width)
      if candidate(maze, cell) {
        let distance = abs(cell.x - maze.stairs.x) + abs(cell.y - maze.stairs.y)
        if distance > best {
          chosen = cell
          best = distance
        }
      }
      offset += 1
    }
    return chosen
  }

  private static func candidate(_ maze: Maze, _ cell: CellPoint) -> Bool {
    if cell == maze.start || cell == maze.stairs {
      return false
    }
    switch maze.tile(at: cell) {
    case .floor:
      return true
    case .wall, .stairs:
      return false
    }
  }
}
