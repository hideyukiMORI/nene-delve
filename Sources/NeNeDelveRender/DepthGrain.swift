import NeNeDelveCore

/// 壁が遠い列の床に、升の角を一つ置く。線にはしない。
enum DepthGrain {
  /// 壁までの垂直距離がこれ未満の列は、今の床のまま。
  static let reach = 4

  /// これより近い画面上の角は、近い方だけを残す。
  private static let columnGap = 6
  private static let rowGap = 2

  struct Dot: Equatable {
    let column: Int
    let row: Int
  }

  static func dots(maze: Maze, gaze: Gaze, span: GridSpan, hits: [DepthHit]) -> [Dot] {
    let viewHeight = span.height - ScreenText.hudRows
    if viewHeight <= 1 || span.width <= 0 || hits.count != span.width {
      return []
    }
    let view = View(maze: maze, gaze: gaze, span: span, hits: hits, viewHeight: viewHeight)
    var near = Array(repeating: Double.greatestFiniteMagnitude, count: span.width * viewHeight)
    var y = 0
    while y <= maze.span.height {
      var x = 0
      while x <= maze.span.width {
        record(&near, view: view, at: CellPoint(x: x, y: y))
        x += 1
      }
      y += 1
    }
    return gather(near, width: span.width, viewHeight: viewHeight)
  }

  private struct View {
    let maze: Maze
    let gaze: Gaze
    let span: GridSpan
    let hits: [DepthHit]
    let viewHeight: Int
  }

  private struct Sight {
    let lateral: Double
    let depth: Double
  }

  private struct Placed {
    let column: Int
    let row: Int
    let depth: Double
  }

  private static func record(_ near: inout [Double], view: View, at corner: CellPoint) {
    if !opens(view.maze, at: corner) {
      return
    }
    guard let placed = project(corner, view: view) else {
      return
    }
    let index = placed.row * view.span.width + placed.column
    if placed.depth < near[index] {
      near[index] = placed.depth
    }
  }

  private static func project(_ corner: CellPoint, view: View) -> Placed? {
    guard let sight = sight(corner, view: view) else {
      return nil
    }
    let column = Int((((sight.lateral / sight.depth) + 1) / 2 * Double(view.span.width)).rounded())
    if !shows(column, depth: sight.depth, view: view) {
      return nil
    }
    guard let row = floorRow(sight.depth, view: view, column: column) else {
      return nil
    }
    return Placed(column: column, row: row, depth: sight.depth)
  }

  private static func sight(_ corner: CellPoint, view: View) -> Sight? {
    let origin = DepthEye.origin(view.gaze)
    let heading = DepthCaster.aim(view.gaze.facing)
    let skew = DepthCaster.plane(heading)
    let det = skew.x * heading.y - heading.x * skew.y
    if det == 0 {
      return nil
    }
    let dx = Double(corner.x) - origin.x
    let dy = Double(corner.y) - origin.y
    let inv = 1 / det
    let depth = inv * (-skew.y * dx + skew.x * dy)
    if depth <= 0.05 {
      return nil
    }
    let lateral = inv * (heading.y * dx - heading.x * dy)
    return Sight(lateral: lateral, depth: depth)
  }

  private static func shows(_ column: Int, depth: Double, view: View) -> Bool {
    if column < 0 || column >= view.hits.count {
      return false
    }
    let wall = view.hits[column].distance
    return wall >= Double(reach) && depth < wall
  }

  private static func floorRow(_ depth: Double, view: View, column: Int) -> Int? {
    let split = Double(view.viewHeight) / 2 - Double(view.gaze.horizon)
    let horizon = min(max(split, 0), Double(view.viewHeight))
    if horizon <= 0 {
      return nil
    }
    let row = Int((horizon + horizon / depth).rounded())
    if Double(row) <= horizon || row >= view.viewHeight {
      return nil
    }
    let plane = DepthPlane.across(
      view.hits[column].distance, viewHeight: view.viewHeight, horizon: view.gaze.horizon)
    if row <= plane.bottom {
      return nil
    }
    return row
  }

  private static func opens(_ maze: Maze, at corner: CellPoint) -> Bool {
    open(maze, CellPoint(x: corner.x - 1, y: corner.y - 1))
      || open(maze, CellPoint(x: corner.x, y: corner.y - 1))
      || open(maze, CellPoint(x: corner.x - 1, y: corner.y))
      || open(maze, CellPoint(x: corner.x, y: corner.y))
  }

  private static func open(_ maze: Maze, _ point: CellPoint) -> Bool {
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

  private static func gather(_ near: [Double], width: Int, viewHeight: Int) -> [Dot] {
    var placed: [Placed] = []
    var row = 0
    while row < viewHeight {
      var column = 0
      while column < width {
        let depth = near[row * width + column]
        if depth < Double.greatestFiniteMagnitude {
          placed.append(Placed(column: column, row: row, depth: depth))
        }
        column += 1
      }
      row += 1
    }
    return space(placed)
  }

  private static func space(_ placed: [Placed]) -> [Dot] {
    var ordered = placed
    ordered.sort { $0.depth < $1.depth }
    var kept: [Dot] = []
    var index = 0
    while index < ordered.count {
      let dot = ordered[index]
      if clear(dot, kept: kept) {
        kept.append(Dot(column: dot.column, row: dot.row))
      }
      index += 1
    }
    return kept
  }

  private static func clear(_ dot: Placed, kept: [Dot]) -> Bool {
    var index = 0
    while index < kept.count {
      let gapX = abs(dot.column - kept[index].column)
      let gapY = abs(dot.row - kept[index].row)
      if gapX < columnGap && gapY < rowGap {
        return false
      }
      index += 1
    }
    return true
  }
}
