public struct Maze: Equatable, Sendable {
  public let kind: MazeKind
  public let span: GridSpan
  public let tiles: [Tile]
  public let ends: MazeEnds

  public var start: CellPoint {
    ends.start
  }

  public var stairs: CellPoint {
    ends.stairs
  }

  public func tile(at point: CellPoint) -> Tile {
    tiles[span.offset(point)]
  }

  func isOpenUnseen(_ point: CellPoint, seen: [Bool]) -> Bool {
    if !span.contains(point) {
      return false
    }
    if seen[span.offset(point)] {
      return false
    }
    switch tile(at: point) {
    case .wall:
      return false
    case .floor, .stairs:
      return true
    }
  }

  init(span: GridSpan, tiles: [Tile], ends: MazeEnds, kind: MazeKind) {
    self.kind = kind
    self.span = span
    self.tiles = tiles
    self.ends = ends
  }
}
