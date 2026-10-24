import NeNeDelveCore

/// 表示だけの視線。走行の一歩は Core が持つ。
public enum Sightline {
  public static func opening(from: CellPoint, toward: CellPoint) -> Direction {
    advanced(from: from, to: toward, facing: .north)
  }

  /// 壁を正面にしない。開いている隣のうち、階段へ一番近づく方を向く。
  public static func opening(in maze: Maze, from: CellPoint, toward: CellPoint) -> Direction {
    var chosen: Direction?
    var gain = Int.min
    for facing in headings {
      let next = stepped(from, facing)
      if !passes(maze, next) {
        continue
      }
      let closer = span(from, toward) - span(next, toward)
      if chosen == nil || closer > gain {
        chosen = facing
        gain = closer
      }
    }
    if let chosen {
      return chosen
    }
    return opening(from: from, toward: toward)
  }

  public static func advanced(from: CellPoint, to: CellPoint, facing: Direction) -> Direction {
    let column = to.x - from.x
    let row = to.y - from.y
    if column == 0 && row == 0 {
      return facing
    }
    if abs(column) >= abs(row) && column != 0 {
      return column > 0 ? .east : .west
    }
    if row > 0 {
      return .south
    }
    if row < 0 {
      return .north
    }
    return facing
  }

  private static let headings: [Direction] = [.north, .east, .south, .west]

  private static func stepped(_ from: CellPoint, _ facing: Direction) -> CellPoint {
    switch facing {
    case .north:
      CellPoint(x: from.x, y: from.y - 1)
    case .east:
      CellPoint(x: from.x + 1, y: from.y)
    case .south:
      CellPoint(x: from.x, y: from.y + 1)
    case .west:
      CellPoint(x: from.x - 1, y: from.y)
    }
  }

  private static func passes(_ maze: Maze, _ point: CellPoint) -> Bool {
    if !maze.span.contains(point) {
      return false
    }
    switch maze.tile(at: point) {
    case .wall:
      return false
    case .floor, .stairs:
      return true
    }
  }

  private static func span(_ from: CellPoint, _ toward: CellPoint) -> Int {
    abs(toward.x - from.x) + abs(toward.y - from.y)
  }
}
