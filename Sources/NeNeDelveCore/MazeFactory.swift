public enum MazeFactory {
  public static func make(kind: MazeKind, seed: Seed, span: GridSpan) -> MazePlan {
    switch kind {
    case .filledGrid:
      filled(seed: seed, span: span)
    case .rooms:
      rooms(seed: seed, span: span)
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
