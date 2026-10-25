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

  var veil: MazeVeil {
    plate.veil
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
    let kept = MazePlate(ends: marked, dug: dug, veil: plate.veil)
    return Maze(span: span, tiles: next, plate: kept, kind: kind)
  }

  func opening(_ points: [CellPoint]) -> Maze {
    if points.isEmpty {
      return self
    }
    let veil = plate.veil
    var next = tiles
    var opened = dug
    for point in points where span.contains(point) {
      switch tile(at: point) {
      case .wall:
        next[span.offset(point)] = .floor
        opened.append(point)
      case .floor, .stairs:
        break
      }
    }
    let kept = MazePlate(ends: ends, dug: opened, veil: veil)
    return Maze(span: span, tiles: next, plate: kept, kind: kind)
  }

  func veiled(_ veil: MazeVeil) -> Maze {
    let kept = MazePlate(ends: ends, dug: dug, veil: veil)
    return Maze(span: span, tiles: tiles, plate: kept, kind: kind)
  }

  func lantern(around origin: CellPoint) -> Maze {
    var next = tiles
    var index = 0
    while index < next.count {
      let point = CellPoint(x: index % span.width, y: index / span.width)
      let distance = abs(point.x - origin.x) + abs(point.y - origin.y)
      if distance > DarkFloor.radius {
        next[index] = .wall
      }
      index += 1
    }
    return Maze(span: span, tiles: next, plate: plate, kind: kind)
  }

  func cycled(keeping blocked: [CellPoint]) -> Maze {
    let count = veil.shifts.count
    if count == 0 {
      return self
    }
    let nextPhase = (veil.phase + 1) % (count + 1)
    var next = tiles
    closeShift(&next, index: veil.phase, count: count, blocked: blocked)
    openShift(&next, index: nextPhase, count: count)
    let updated = MazeVeil(shade: veil.shade, shifts: veil.shifts, phase: nextPhase)
    let kept = MazePlate(ends: ends, dug: dug, veil: updated)
    return Maze(span: span, tiles: next, plate: kept, kind: kind)
  }

  private func closeShift(
    _ tiles: inout [Tile], index: Int, count: Int, blocked: [CellPoint]
  ) {
    if index >= count {
      return
    }
    let point = veil.shifts[index]
    if blocked.contains(point) || !span.contains(point) {
      return
    }
    if tiles[span.offset(point)] == .floor {
      tiles[span.offset(point)] = .wall
    }
  }

  private func openShift(_ tiles: inout [Tile], index: Int, count: Int) {
    if index >= count || !span.contains(veil.shifts[index]) {
      return
    }
    let point = veil.shifts[index]
    if tiles[span.offset(point)] == .wall {
      tiles[span.offset(point)] = .floor
    }
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
