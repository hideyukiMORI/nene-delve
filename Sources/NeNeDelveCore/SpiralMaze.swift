/// 渦巻き回廊。環のあいだは壁一枚で、接続は一箇所。
enum SpiralMaze {
  static func maze(seed _: Seed, span: GridSpan) -> Maze {
    MazeStamp.seal(tiles: carve(span), span: span, kind: .spiral)
  }

  private struct Ring {
    let left: Int
    let top: Int
    let right: Int
    let bottom: Int

    var inner: Ring {
      Ring(left: left + 2, top: top + 2, right: right - 2, bottom: bottom - 2)
    }

    var hasRoom: Bool {
      left <= right && top <= bottom
    }
  }

  private static func carve(_ span: GridSpan) -> [Tile] {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var ring = Ring(left: 1, top: 1, right: span.width - 2, bottom: span.height - 2)
    var guardRing = 0
    while ring.hasRoom && guardRing < span.count {
      trace(&tiles, span: span, ring: ring)
      ring = ring.inner
      guardRing += 1
    }
    return tiles
  }

  private static func trace(_ tiles: inout [Tile], span: GridSpan, ring: Ring) {
    let topLeft = CellPoint(x: ring.left, y: ring.top)
    let topRight = CellPoint(x: ring.right, y: ring.top)
    let bottomRight = CellPoint(x: ring.right, y: ring.bottom)
    let bottomLeft = CellPoint(x: ring.left, y: ring.bottom)
    MazeInk.line(&tiles, span: span, from: topLeft, to: topRight)
    if ring.top == ring.bottom {
      return
    }
    MazeInk.line(&tiles, span: span, from: topRight, to: bottomRight)
    if ring.left == ring.right {
      return
    }
    MazeInk.line(&tiles, span: span, from: bottomRight, to: bottomLeft)
    rise(&tiles, span: span, ring: ring, from: bottomLeft)
  }

  private static func rise(_ tiles: inout [Tile], span: GridSpan, ring: Ring, from: CellPoint) {
    let stop = CellPoint(x: ring.left, y: ring.top + 2)
    if ring.bottom >= stop.y {
      MazeInk.line(&tiles, span: span, from: from, to: stop)
    }
    let next = ring.inner
    if !next.hasRoom {
      return
    }
    MazeInk.line(&tiles, span: span, from: stop, to: CellPoint(x: next.left, y: next.top))
  }
}
