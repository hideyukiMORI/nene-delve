struct RoomMaze {
  private var tiles: [Tile]
  private var rooms: [RoomBox]
  private var rng: SplitMix64
  private let span: GridSpan

  init(seed: Seed, span: GridSpan) {
    self.span = span
    tiles = Array(repeating: .wall, count: span.count)
    rooms = []
    rng = SplitMix64(seed: seed)
  }

  mutating func digAll() {
    placeRooms()
    if rooms.count > 1 {
      carveTree()
      carveLoops()
    }
  }

  func maze() -> Maze {
    var finished = tiles
    let stairs = stairPoint()
    finished[span.offset(stairs)] = .stairs
    let ends = MazeEnds(start: rooms[0].center, stairs: stairs)
    return Maze(span: span, tiles: finished, ends: ends, kind: .rooms)
  }

  private mutating func placeRooms() {
    var tries = 0
    while rooms.count < roomGoal(), tries < roomGoal() * 16 {
      tries += 1
      guard let room = propose(), accepts(room) else {
        continue
      }
      rooms.append(room)
      paint(room)
    }
    if rooms.isEmpty {
      let room = fallback()
      rooms.append(room)
      paint(room)
    }
  }

  private func roomGoal() -> Int {
    max(2, min(12, span.width * span.height / 40))
  }

  private mutating func propose() -> RoomBox? {
    let maxWidth = min(9, span.width - 2)
    let maxHeight = min(7, span.height - 2)
    if maxWidth < 3 || maxHeight < 3 {
      return nil
    }
    let width = 3 + Int(roll() % UInt64(maxWidth - 2))
    let height = 3 + Int(roll() % UInt64(maxHeight - 2))
    let limitX = span.width - width - 1
    let limitY = span.height - height - 1
    if limitX < 1 || limitY < 1 {
      return nil
    }
    let x = 1 + Int(roll() % UInt64(limitX))
    let y = 1 + Int(roll() % UInt64(limitY))
    return RoomBox(origin: CellPoint(x: x, y: y), width: width, height: height)
  }

  private func accepts(_ room: RoomBox) -> Bool {
    for other in rooms where room.crowds(other) {
      return false
    }
    return true
  }

  private func fallback() -> RoomBox {
    RoomBox(
      origin: CellPoint(x: 1, y: 1), width: min(3, span.width - 2), height: min(3, span.height - 2))
  }

  private mutating func paint(_ room: RoomBox) {
    var y = 0
    while y < room.height {
      var x = 0
      while x < room.width {
        open(CellPoint(x: room.origin.x + x, y: room.origin.y + y))
        x += 1
      }
      y += 1
    }
  }

  private mutating func carveTree() {
    var parent = Array(0..<rooms.count)
    for link in links() where unite(&parent, link.from, link.to) {
      corridor(rooms[link.from].center, rooms[link.to].center)
    }
  }

  private mutating func carveLoops() {
    var added = 0
    let cap = max(rooms.count / 3, 1)
    for link in links() {
      if added >= cap {
        return
      }
      if roll() % 3 != 0 {
        continue
      }
      corridor(rooms[link.from].center, rooms[link.to].center)
      added += 1
    }
  }

  private func links() -> [RoomLink] {
    var found: [RoomLink] = []
    var left = 0
    while left < rooms.count {
      var right = left + 1
      while right < rooms.count {
        let weight = distance(rooms[left].center, rooms[right].center)
        found.append(RoomLink(from: left, to: right, weight: weight))
        right += 1
      }
      left += 1
    }
    return found.sorted { $0.weight < $1.weight }
  }

  private func distance(_ from: CellPoint, _ to: CellPoint) -> Int {
    abs(from.x - to.x) + abs(from.y - to.y)
  }

  private mutating func corridor(_ from: CellPoint, _ to: CellPoint) {
    var x = from.x
    while x != to.x {
      x += x < to.x ? 1 : -1
      open(CellPoint(x: x, y: from.y))
    }
    var y = from.y
    while y != to.y {
      y += y < to.y ? 1 : -1
      open(CellPoint(x: to.x, y: y))
    }
  }

  private mutating func open(_ point: CellPoint) {
    if point.x <= 0 || point.y <= 0 || point.x >= span.width - 1 || point.y >= span.height - 1 {
      return
    }
    tiles[span.offset(point)] = .floor
  }

  private mutating func roll() -> UInt64 {
    let (value, next) = rng.next()
    rng = next
    return value
  }

  private func stairPoint() -> CellPoint {
    let room = rooms[rooms.count - 1]
    let start = rooms[0].center
    var y = room.origin.y
    while y < room.origin.y + room.height {
      var x = room.origin.x
      while x < room.origin.x + room.width {
        let point = CellPoint(x: x, y: y)
        if point != start {
          return point
        }
        x += 1
      }
      y += 1
    }
    return start
  }

  private func find(_ parent: [Int], _ index: Int) -> Int {
    var cursor = index
    while parent[cursor] != cursor {
      cursor = parent[cursor]
    }
    return cursor
  }

  private func unite(_ parent: inout [Int], _ left: Int, _ right: Int) -> Bool {
    let rootLeft = find(parent, left)
    let rootRight = find(parent, right)
    if rootLeft == rootRight {
      return false
    }
    parent[rootRight] = rootLeft
    return true
  }
}
