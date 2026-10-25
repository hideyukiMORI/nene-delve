public struct Maze: Equatable, Sendable {
  public let kind: MazeKind
  public let span: GridSpan
  public let tiles: [Tile]
  private let plate: MazePlate

  public var ends: MazeEnds {
    plate.ends
  }

  public var dug: [CellPoint] {
    plate.dug
  }

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

  func withAscent(_ point: CellPoint) -> Maze {
    var next = tiles
    next[span.offset(point)] = .stairs
    let marked = MazeEnds(start: start, stairs: stairs, ascent: point)
    let kept = MazePlate(ends: marked, dug: dug)
    return Maze(span: span, tiles: next, plate: kept, kind: kind)
  }

  init(span: GridSpan, tiles: [Tile], ends: MazeEnds, kind: MazeKind) {
    self.init(span: span, tiles: tiles, plate: MazePlate(ends: ends), kind: kind)
  }

  init(span: GridSpan, tiles: [Tile], plate: MazePlate, kind: MazeKind) {
    self.kind = kind
    self.span = span
    self.tiles = tiles
    self.plate = plate
  }
}
