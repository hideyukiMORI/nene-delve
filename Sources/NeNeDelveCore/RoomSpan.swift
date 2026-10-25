/// 部屋の升。通路は幅が 1 なので、2 升四方の開きだけを部屋にする。
public enum RoomSpan {
  public static func contains(_ point: CellPoint, in maze: Maze) -> Bool {
    if maze.kind != .rooms {
      return false
    }
    return square(CellPoint(x: point.x, y: point.y), maze)
      || square(CellPoint(x: point.x - 1, y: point.y), maze)
      || square(CellPoint(x: point.x, y: point.y - 1), maze)
      || square(CellPoint(x: point.x - 1, y: point.y - 1), maze)
  }

  public static func crossing(_ world: FloorWorld) -> Bool {
    if !contains(world.walk.explorer.position, in: world.walk.maze) {
      return false
    }
    return moved(world)
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

  private static func square(_ origin: CellPoint, _ maze: Maze) -> Bool {
    let east = CellPoint(x: origin.x + 1, y: origin.y)
    let south = CellPoint(x: origin.x, y: origin.y + 1)
    let far = CellPoint(x: origin.x + 1, y: origin.y + 1)
    return open(origin, maze) && open(east, maze) && open(south, maze) && open(far, maze)
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
