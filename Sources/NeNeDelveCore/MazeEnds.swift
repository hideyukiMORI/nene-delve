public struct MazeEnds: Equatable, Sendable {
  public let start: CellPoint
  public let stairs: CellPoint
  public let ascent: CellPoint?

  public init(start: CellPoint, stairs: CellPoint, ascent: CellPoint? = nil) {
    self.start = start
    self.stairs = stairs
    self.ascent = ascent
  }
}
