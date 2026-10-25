/// 明かりの外を壁として描く。探索の迷路は変えない。
public enum DarkFloor {
  public static let radius = 4

  public static func masked(_ world: FloorWorld) -> FloorWorld {
    let maze = world.walk.maze
    if !maze.veil.shade {
      return world
    }
    return world.replacing(maze: maze.lantern(around: world.walk.explorer.position))
  }
}
