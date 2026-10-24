public struct MazeEnds: Equatable, Sendable {
  public let start: CellPoint
  public let stairs: CellPoint

  public init(start: CellPoint, stairs: CellPoint) {
    self.start = start
    self.stairs = stairs
  }
}
