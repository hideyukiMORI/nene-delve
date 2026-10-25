/// 迷路の端と、床が最初に開いた順。修飾は種類とは別の層。
public struct MazePlate: Equatable, Sendable {
  public let ends: MazeEnds
  public let dug: [CellPoint]
  let veil: MazeVeil

  public init(ends: MazeEnds, dug: [CellPoint] = []) {
    self.init(ends: ends, dug: dug, veil: .plain)
  }

  init(ends: MazeEnds, dug: [CellPoint] = [], veil: MazeVeil) {
    self.ends = ends
    self.dug = dug
    self.veil = veil
  }
}
