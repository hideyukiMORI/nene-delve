/// 完全迷路の行き止まりから、すでに床がある側へ開ける壁。
enum Braid {
  static func caps(_ maze: Maze) -> [CellPoint] {
    var found: [CellPoint] = []
    var y = 1
    while y < maze.span.height - 1 {
      collect(maze, y: y, into: &found)
      y += 1
    }
    return found
  }

  private static func collect(_ maze: Maze, y: Int, into found: inout [CellPoint]) {
    var x = 1
    while x < maze.span.width - 1 {
      let here = CellPoint(x: x, y: y)
      if let cap = cap(maze, at: here), !found.contains(cap) {
        found.append(cap)
      }
      x += 1
    }
  }

  private static func cap(_ maze: Maze, at here: CellPoint) -> CellPoint? {
    if !open(maze, here) {
      return nil
    }
    guard let exit = only(maze, here) else {
      return nil
    }
    let wall = CellPoint(x: here.x * 2 - exit.x, y: here.y * 2 - exit.y)
    let beyond = CellPoint(x: wall.x * 2 - here.x, y: wall.y * 2 - here.y)
    if !interior(maze, wall) || !maze.span.contains(beyond) {
      return nil
    }
    if maze.tile(at: wall) != .wall || !open(maze, beyond) {
      return nil
    }
    return wall
  }

  private static func only(_ maze: Maze, _ here: CellPoint) -> CellPoint? {
    var found: CellPoint?
    for direction in Direction.cardinal {
      let next = CellPoint(x: here.x + direction.stepX, y: here.y + direction.stepY)
      if !open(maze, next) {
        continue
      }
      if found != nil {
        return nil
      }
      found = next
    }
    return found
  }

  private static func interior(_ maze: Maze, _ point: CellPoint) -> Bool {
    point.x > 0 && point.y > 0 && point.x < maze.span.width - 1 && point.y < maze.span.height - 1
  }

  private static func open(_ maze: Maze, _ point: CellPoint) -> Bool {
    if !maze.span.contains(point) {
      return false
    }
    switch maze.tile(at: point) {
    case .wall:
      return false
    case .floor, .stairs:
      return true
    }
  }
}
