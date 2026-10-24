public struct Explorer: Equatable, Sendable {
  public let position: CellPoint
  public let path: [CellPoint]
  public let seen: [Bool]

  public static func begin(_ maze: Maze) -> Explorer {
    var seen = Array(repeating: false, count: maze.span.count)
    seen[maze.span.offset(maze.start)] = true
    return Explorer(position: maze.start, path: [maze.start], seen: seen)
  }

  func step(_ maze: Maze, rng: inout SplitMix64) -> ExploreMove {
    let choices = unvisitedNeighbors(maze)
    if let next = pick(choices, rng: &rng) {
      return advance(maze, to: next)
    }
    return backtrack()
  }

  private func unvisitedNeighbors(_ maze: Maze) -> [CellPoint] {
    var found: [CellPoint] = []
    for direction in Direction.cardinal {
      let next = CellPoint(x: position.x + direction.stepX, y: position.y + direction.stepY)
      if maze.isOpenUnseen(next, seen: seen) {
        found.append(next)
      }
    }
    return found
  }

  private func pick(_ choices: [CellPoint], rng: inout SplitMix64) -> CellPoint? {
    if choices.isEmpty {
      return nil
    }
    let (value, generator) = rng.next()
    rng = generator
    let index = Int(value % UInt64(choices.count))
    return choices[index]
  }

  private func advance(_ maze: Maze, to next: CellPoint) -> ExploreMove {
    var updated = seen
    updated[maze.span.offset(next)] = true
    let moved = Explorer(position: next, path: path + [next], seen: updated)
    switch maze.tile(at: next) {
    case .stairs:
      return .arrived(moved)
    case .floor, .wall:
      return .moved(moved)
    }
  }

  private func backtrack() -> ExploreMove {
    if path.count < 2 {
      return .stuck
    }
    let shortened = Array(path.dropLast())
    let previous = shortened[shortened.count - 1]
    return .moved(Explorer(position: previous, path: shortened, seen: seen))
  }
}
