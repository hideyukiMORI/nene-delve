/// 次の升が階段か、その隣でいまより近いときだけ急ぐ。
public enum StairApproach {
  public static func closing(_ world: FloorWorld) -> Bool {
    guard let next = ahead(world) else {
      return false
    }
    let stairs = world.walk.maze.stairs
    let nextSpan = span(next, stairs)
    if nextSpan > 1 {
      return false
    }
    let here = world.walk.explorer.position
    return nextSpan < span(here, stairs)
  }

  private static func ahead(_ world: FloorWorld) -> CellPoint? {
    let origin = world.walk.explorer.position
    switch FloorReducer.tick(world) {
    case .running(let stepped):
      let next = stepped.walk.explorer.position
      if next == origin {
        return nil
      }
      return next
    case .descended(let stood), .ascended(let stood):
      let next = stood.walk.explorer.position
      if next == origin {
        return nil
      }
      return next
    case .stuck:
      return nil
    }
  }

  private static func span(_ from: CellPoint, _ to: CellPoint) -> Int {
    abs(from.x - to.x) + abs(from.y - to.y)
  }
}
