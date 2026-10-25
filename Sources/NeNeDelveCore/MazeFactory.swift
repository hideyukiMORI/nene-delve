public enum MazeFactory {
  public static func make(kind: MazeKind, seed: Seed, span: GridSpan) -> MazePlan {
    switch carved(kind: kind, seed: seed, span: span) {
    case .tooSmall:
      .tooSmall
    case .maze(let maze):
      .maze(FloorShade.applied(maze, seed: seed))
    }
  }

  private static func carved(kind: MazeKind, seed: Seed, span: GridSpan) -> MazePlan {
    guard let fitted = span.fittingMaze() else {
      return .tooSmall
    }
    switch kind {
    case .filledGrid:
      return filled(seed: seed, span: fitted)
    case .rooms:
      return rooms(seed: seed, span: fitted)
    case .cavern:
      return .maze(CavernMaze.maze(seed: seed, span: fitted))
    case .loops:
      return .maze(LoopMaze.maze(seed: seed, span: fitted))
    case .circuit:
      return .maze(CircuitMaze.maze(seed: seed, span: fitted))
    case .racks:
      return .maze(RackMaze.maze(seed: seed, span: fitted))
    case .islands:
      return .maze(IslandMaze.maze(seed: seed, span: fitted))
    case .pillars:
      return .maze(PillarMaze.maze(seed: seed, span: fitted))
    case .spiral:
      return .maze(SpiralMaze.maze(seed: seed, span: fitted))
    case .shifting:
      return .maze(ShiftMaze.maze(seed: seed, span: fitted))
    case .blocks:
      return .maze(BlockMaze.maze(seed: seed, span: fitted))
    }
  }

  public static func rooms(seed: Seed, span: GridSpan) -> MazePlan {
    guard let fitted = span.fittingMaze() else {
      return .tooSmall
    }
    var field = RoomMaze(seed: seed, span: fitted)
    field.digAll()
    return .maze(field.maze())
  }

  public static func filled(seed: Seed, span: GridSpan) -> MazePlan {
    guard let fitted = span.fittingMaze() else {
      return .tooSmall
    }
    var carve = CarveState(seed: seed, span: fitted)
    carve.digAll()
    return .maze(carve.maze())
  }
}
