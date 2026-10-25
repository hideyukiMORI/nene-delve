/// 迷路の端と、床が最初に開いた順。
public struct MazePlate: Equatable, Sendable {
  public let ends: MazeEnds
  public let dug: [CellPoint]

  public init(ends: MazeEnds, dug: [CellPoint] = []) {
    self.ends = ends
    self.dug = dug
  }
}
