/// 生成器が床を書く場所。外枠は壁のままにする。
enum MazeInk {
  static func floor(_ tiles: inout [Tile], span: GridSpan, at point: CellPoint) {
    if !interior(span, point) {
      return
    }
    tiles[span.offset(point)] = .floor
  }

  static func line(_ tiles: inout [Tile], span: GridSpan, from: CellPoint, to: CellPoint) {
    var x = from.x
    var y = from.y
    var guardStep = 0
    while guardStep < span.count {
      floor(&tiles, span: span, at: CellPoint(x: x, y: y))
      if x == to.x && y == to.y {
        return
      }
      advance(&x, &y, toward: to)
      guardStep += 1
    }
  }

  private static func interior(_ span: GridSpan, _ point: CellPoint) -> Bool {
    span.contains(point) && point.x > 0 && point.y > 0 && point.x < span.width - 1
      && point.y < span.height - 1
  }

  private static func advance(_ x: inout Int, _ y: inout Int, toward: CellPoint) {
    if x != toward.x {
      x += stride(x, toward.x)
      return
    }
    y += stride(y, toward.y)
  }

  private static func stride(_ from: Int, _ to: Int) -> Int {
    if to > from {
      return 1
    }
    return -1
  }
}
