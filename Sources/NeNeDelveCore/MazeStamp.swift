/// 生成器が塗った床を、一つの到達できる迷路に閉じる。
enum MazeStamp {
  static func seal(
    tiles: [Tile], span: GridSpan, kind: MazeKind, veil: MazeVeil = .plain
  ) -> Maze {
    stamp(ensured(border(tiles, span: span), span: span), span: span, kind: kind, veil: veil)
  }

  static func firstOpen(_ tiles: [Tile], span: GridSpan) -> CellPoint? {
    var index = 0
    while index < tiles.count {
      if tiles[index] != .wall {
        return CellPoint(x: index % span.width, y: index / span.width)
      }
      index += 1
    }
    return nil
  }

  static func flood(_ tiles: [Tile], span: GridSpan, from start: CellPoint) -> [Bool] {
    var seen = Array(repeating: false, count: span.count)
    for point in breadth(tiles, span: span, from: start) {
      seen[span.offset(point)] = true
    }
    return seen
  }

  static func firstHidden(_ tiles: [Tile], span: GridSpan, seen: [Bool]) -> CellPoint? {
    var index = 0
    while index < tiles.count {
      if tiles[index] != .wall && !seen[index] {
        return CellPoint(x: index % span.width, y: index / span.width)
      }
      index += 1
    }
    return nil
  }

  static func nearest(_ seen: [Bool], span: GridSpan, to point: CellPoint) -> CellPoint {
    var best = point
    var bestDistance = span.count
    var found = false
    var index = 0
    while index < seen.count {
      if seen[index] {
        let candidate = CellPoint(x: index % span.width, y: index / span.width)
        let distance = abs(candidate.x - point.x) + abs(candidate.y - point.y)
        if !found || distance < bestDistance {
          best = candidate
          bestDistance = distance
          found = true
        }
      }
      index += 1
    }
    return best
  }

  private static func border(_ tiles: [Tile], span: GridSpan) -> [Tile] {
    var next = tiles
    var index = 0
    while index < next.count {
      let x = index % span.width
      let y = index / span.width
      if x == 0 || y == 0 || x == span.width - 1 || y == span.height - 1 {
        next[index] = .wall
      }
      index += 1
    }
    return next
  }

  private static func ensured(_ tiles: [Tile], span: GridSpan) -> [Tile] {
    guard let start = firstOpen(tiles, span: span) else {
      return corridor(span)
    }
    let seen = flood(tiles, span: span, from: start)
    if openCount(seen) < 2 {
      return corridor(span)
    }
    return onlyReached(tiles, span: span, seen: seen)
  }

  private static func onlyReached(_ tiles: [Tile], span: GridSpan, seen: [Bool]) -> [Tile] {
    var next = tiles
    var index = 0
    while index < next.count {
      if next[index] != .wall && !seen[index] {
        next[index] = .wall
      }
      index += 1
    }
    return next
  }

  private static func corridor(_ span: GridSpan) -> [Tile] {
    var tiles = Array(repeating: Tile.wall, count: span.count)
    tiles[span.offset(CellPoint(x: 1, y: 1))] = .floor
    tiles[span.offset(CellPoint(x: 2, y: 1))] = .floor
    return tiles
  }

  private static func stamp(
    _ tiles: [Tile], span: GridSpan, kind: MazeKind, veil: MazeVeil
  ) -> Maze {
    let start = firstOpen(tiles, span: span) ?? CellPoint(x: 1, y: 1)
    let visited = breadth(tiles, span: span, from: start)
    let stairs = visited.last ?? CellPoint(x: 2, y: 1)
    var finished = tiles
    write(&finished, span: span, at: start, tile: .floor)
    if stairs != start {
      write(&finished, span: span, at: stairs, tile: .stairs)
    }
    let ends = MazeEnds(start: start, stairs: stairs)
    let plate = MazePlate(ends: ends, dug: visited, veil: veil)
    return Maze(span: span, tiles: finished, plate: plate, kind: kind)
  }

  private static func write(
    _ tiles: inout [Tile], span: GridSpan, at point: CellPoint, tile: Tile
  ) {
    if span.contains(point) {
      tiles[span.offset(point)] = tile
    }
  }

  private static func openCount(_ seen: [Bool]) -> Int {
    var count = 0
    for cell in seen where cell {
      count += 1
    }
    return count
  }

  private struct Walk {
    var queue: [CellPoint]
    var seen: [Bool]
  }

  private static func breadth(_ tiles: [Tile], span: GridSpan, from start: CellPoint) -> [CellPoint]
  {
    if !open(tiles, span: span, at: start) {
      return []
    }
    var seen = Array(repeating: false, count: span.count)
    seen[span.offset(start)] = true
    var walk = Walk(queue: [start], seen: seen)
    var cursor = 0
    while cursor < walk.queue.count {
      enqueue(tiles, span: span, from: walk.queue[cursor], walk: &walk)
      cursor += 1
    }
    return walk.queue
  }

  private static func enqueue(
    _ tiles: [Tile], span: GridSpan, from point: CellPoint, walk: inout Walk
  ) {
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      push(tiles, span: span, next: next, walk: &walk)
    }
  }

  private static func push(
    _ tiles: [Tile], span: GridSpan, next: CellPoint, walk: inout Walk
  ) {
    if !open(tiles, span: span, at: next) || walk.seen[span.offset(next)] {
      return
    }
    walk.seen[span.offset(next)] = true
    walk.queue.append(next)
  }

  private static func open(_ tiles: [Tile], span: GridSpan, at point: CellPoint) -> Bool {
    if !span.contains(point) {
      return false
    }
    return tiles[span.offset(point)] != .wall
  }
}
