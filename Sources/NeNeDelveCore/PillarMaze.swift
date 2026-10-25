/// 広間に偶数の升へ柱を立てる。高い階は扉一つで二つに割る。
enum PillarMaze {
  static func maze(seed _: Seed, span: GridSpan) -> Maze {
    MazeStamp.seal(tiles: carve(span), span: span, kind: .pillars)
  }

  private struct Hall {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
  }

  private static func carve(_ span: GridSpan) -> [Tile] {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    if span.height >= 11 {
      split(&tiles, span: span)
    } else {
      let hall = Hall(x: 1, y: 1, width: span.width - 2, height: span.height - 2)
      fill(&tiles, span: span, hall: hall)
    }
    punch(&tiles, span: span)
    return tiles
  }

  private static func split(_ tiles: inout [Tile], span: GridSpan) {
    let mid = span.height / 2
    let upper = Hall(x: 1, y: 1, width: span.width - 2, height: mid - 1)
    let lowerY = mid + 1
    let lower = Hall(x: 1, y: lowerY, width: span.width - 2, height: span.height - lowerY - 1)
    fill(&tiles, span: span, hall: upper)
    fill(&tiles, span: span, hall: lower)
    MazeInk.floor(&tiles, span: span, at: door(span, y: mid))
  }

  private static func door(_ span: GridSpan, y: Int) -> CellPoint {
    var x = span.width / 2
    if x.isMultiple(of: 2) && y.isMultiple(of: 2) {
      x -= 1
    }
    return CellPoint(x: x, y: y)
  }

  private static func fill(_ tiles: inout [Tile], span: GridSpan, hall: Hall) {
    var y = hall.y
    while y < hall.y + hall.height {
      fillRow(&tiles, span: span, hall: hall, y: y)
      y += 1
    }
  }

  private static func fillRow(_ tiles: inout [Tile], span: GridSpan, hall: Hall, y: Int) {
    var x = hall.x
    while x < hall.x + hall.width {
      MazeInk.floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      x += 1
    }
  }

  private static func punch(_ tiles: inout [Tile], span: GridSpan) {
    var y = 2
    while y < span.height - 2 {
      punchRow(&tiles, span: span, y: y)
      y += 2
    }
  }

  private static func punchRow(_ tiles: inout [Tile], span: GridSpan, y: Int) {
    var x = 2
    while x < span.width - 2 {
      let point = CellPoint(x: x, y: y)
      if tiles[span.offset(point)] == .floor {
        tiles[span.offset(point)] = .wall
      }
      x += 2
    }
  }
}
