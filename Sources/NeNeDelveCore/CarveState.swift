struct CarveState {
  private var tiles: [Tile]
  private var stack: [CellPoint]
  private var last: CellPoint
  private var dug: [CellPoint]
  private var rng: SplitMix64
  private let span: GridSpan

  init(seed: Seed, span: GridSpan) {
    self.span = span
    tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    stack = [start]
    last = start
    dug = [start]
    rng = SplitMix64(seed: seed)
    tiles[span.offset(start)] = .floor
  }

  mutating func digAll() {
    while let room = stack.last {
      carve(room)
    }
  }

  func maze() -> Maze {
    var finished = tiles
    finished[span.offset(last)] = .stairs
    let ends = MazeEnds(start: CellPoint(x: 1, y: 1), stairs: last)
    let plate = MazePlate(ends: ends, dug: dug)
    return Maze(span: span, tiles: finished, plate: plate, kind: .filledGrid)
  }

  private mutating func carve(_ room: CellPoint) {
    let choices = candidateRooms(from: room)
    if choices.isEmpty {
      stack.removeLast()
      return
    }
    let next = choices[0]
    openPassage(from: room, to: next)
    stack.append(next)
    last = next
  }

  private mutating func candidateRooms(from room: CellPoint) -> [CellPoint] {
    var found: [CellPoint] = []
    for direction in shuffled() {
      if let next = uncarvedRoom(from: room, direction: direction) {
        found.append(next)
      }
    }
    return found
  }

  private func uncarvedRoom(from room: CellPoint, direction: Direction) -> CellPoint? {
    let next = CellPoint(x: room.x + direction.stepX * 2, y: room.y + direction.stepY * 2)
    if !isRoom(next) {
      return nil
    }
    if tiles[span.offset(next)] != .wall {
      return nil
    }
    return next
  }

  private func isRoom(_ point: CellPoint) -> Bool {
    point.x > 0 && point.y > 0 && point.x < span.width - 1 && point.y < span.height - 1
  }

  private mutating func openPassage(from room: CellPoint, to next: CellPoint) {
    let between = CellPoint(x: (room.x + next.x) / 2, y: (room.y + next.y) / 2)
    tiles[span.offset(between)] = .floor
    tiles[span.offset(next)] = .floor
    dug.append(between)
    dug.append(next)
  }

  private mutating func shuffled() -> [Direction] {
    var items = Direction.cardinal
    var index = items.count - 1
    while index > 0 {
      let (value, generator) = rng.next()
      rng = generator
      let pick = Int(value % UInt64(index + 1))
      items.swapAt(index, pick)
      index -= 1
    }
    return items
  }
}
