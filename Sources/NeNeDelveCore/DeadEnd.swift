/// もう先が無い床。出口が一つで、そこは踏んだあとの升だけ。
public enum DeadEnd {
  public static func cap(_ world: FloorWorld) -> CellPoint? {
    let maze = world.walk.maze
    let here = world.walk.explorer.position
    if !floor(here, maze) {
      return nil
    }
    guard let exit = onlyExit(here, maze) else {
      return nil
    }
    if maze.isOpenUnseen(exit, seen: world.walk.explorer.seen) {
      return nil
    }
    let ahead = CellPoint(x: here.x * 2 - exit.x, y: here.y * 2 - exit.y)
    if wall(ahead, maze) {
      return ahead
    }
    return nil
  }

  public static func leaving(_ world: FloorWorld) -> Bool {
    if cap(world) == nil {
      return false
    }
    return moved(world)
  }

  private static func onlyExit(_ here: CellPoint, _ maze: Maze) -> CellPoint? {
    var found: CellPoint?
    for direction in Direction.cardinal {
      let next = CellPoint(x: here.x + direction.stepX, y: here.y + direction.stepY)
      if !open(next, maze) {
        continue
      }
      if found != nil {
        return nil
      }
      found = next
    }
    return found
  }

  private static func moved(_ world: FloorWorld) -> Bool {
    let origin = world.walk.explorer.position
    switch FloorReducer.tick(world) {
    case .running(let stepped):
      return stepped.walk.explorer.position != origin
    case .descended(let stood), .ascended(let stood):
      return stood.walk.explorer.position != origin
    case .stuck:
      return false
    }
  }

  private static func floor(_ point: CellPoint, _ maze: Maze) -> Bool {
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

  private static func wall(_ point: CellPoint, _ maze: Maze) -> Bool {
    if !maze.span.contains(point) {
      return false
    }
    switch maze.tile(at: point) {
    case .wall:
      return true
    case .floor, .stairs:
      return false
    }
  }

  private static func open(_ point: CellPoint, _ maze: Maze) -> Bool {
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
