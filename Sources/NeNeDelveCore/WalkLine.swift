/// 直前の一歩と同じ方向へ続くときだけ、一歩を短くする。
public enum WalkLine {
  public static func milliseconds(_ world: FloorWorld) -> Int {
    if continues(world) {
      return StepPace.dash.milliseconds
    }
    return world.course.pace.milliseconds
  }

  public static func continues(_ world: FloorWorld) -> Bool {
    guard let traveled = heading(world.walk.explorer) else {
      return false
    }
    guard let next = ahead(world) else {
      return false
    }
    let origin = world.walk.explorer.position
    return heading(from: origin, to: next) == traveled
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
    case .descended(let stood):
      return stood.walk.explorer.position
    case .stuck:
      return nil
    }
  }

  private static func heading(_ explorer: Explorer) -> Direction? {
    let path = explorer.path
    if path.count < 2 {
      return nil
    }
    return heading(from: path[path.count - 2], to: path[path.count - 1])
  }

  private static func heading(from: CellPoint, to: CellPoint) -> Direction? {
    for direction in Direction.cardinal {
      if from.x + direction.stepX == to.x && from.y + direction.stepY == to.y {
        return direction
      }
    }
    return nil
  }
}
