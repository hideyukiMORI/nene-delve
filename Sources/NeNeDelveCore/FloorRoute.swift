enum FloorRoute {
  static func firstStep(_ maze: Maze, from origin: CellPoint, to target: CellPoint) -> CellPoint? {
    if origin == target {
      return nil
    }
    var search = Search(maze: maze, target: target)
    return search.first(from: origin)
  }

  private struct Search {
    let maze: Maze
    let target: CellPoint
    var queue: [CellPoint]
    var parent: [Int]

    init(maze: Maze, target: CellPoint) {
      self.maze = maze
      self.target = target
      self.queue = []
      self.parent = Array(repeating: -1, count: maze.span.count)
    }

    mutating func first(from origin: CellPoint) -> CellPoint? {
      queue = [origin]
      parent[maze.span.offset(origin)] = maze.span.offset(origin)
      var head = 0
      while head < queue.count {
        let current = queue[head]
        head += 1
        if current == target {
          return step(from: origin)
        }
        grow(from: current)
      }
      return nil
    }

    private func step(from origin: CellPoint) -> CellPoint? {
      var cursor = maze.span.offset(target)
      let start = maze.span.offset(origin)
      var previous = cursor
      while cursor != start {
        previous = cursor
        let toward = parent[cursor]
        if toward < 0 || toward == cursor {
          return nil
        }
        cursor = toward
      }
      return CellPoint(x: previous % maze.span.width, y: previous / maze.span.width)
    }

    private mutating func grow(from current: CellPoint) {
      for direction in Direction.cardinal {
        let next = CellPoint(x: current.x + direction.stepX, y: current.y + direction.stepY)
        consider(next, from: current)
      }
    }

    private mutating func consider(_ next: CellPoint, from current: CellPoint) {
      if !maze.span.contains(next) {
        return
      }
      let offset = maze.span.offset(next)
      if parent[offset] >= 0 {
        return
      }
      switch maze.tile(at: next) {
      case .wall:
        return
      case .floor:
        parent[offset] = maze.span.offset(current)
        queue.append(next)
      case .stairs:
        if next == target {
          parent[offset] = maze.span.offset(current)
          queue.append(next)
        }
      }
    }
  }
}
