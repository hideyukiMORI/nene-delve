public struct Explorer: Equatable, Sendable {
  public let position: CellPoint
  public let path: [CellPoint]
  public let seen: [Bool]

  public static func begin(_ maze: Maze) -> Explorer {
    var seen = Array(repeating: false, count: maze.span.count)
    seen[maze.span.offset(maze.start)] = true
    return Explorer(position: maze.start, path: [maze.start], seen: seen)
  }

  func step(
    _ maze: Maze, rng: inout SplitMix64, avoidStairs: Bool, bias: StepBias
  ) -> ExploreMove {
    let choices = unvisitedNeighbors(maze, avoidStairs: avoidStairs, bias: bias)
    if let next = pick(choices, rng: &rng, bias: bias) {
      return advance(maze, to: next)
    }
    return backtrack()
  }

  func move(to next: CellPoint, maze: Maze) -> ExploreMove {
    advance(maze, to: next)
  }

  private func unvisitedNeighbors(_ maze: Maze, avoidStairs: Bool, bias: StepBias) -> [CellPoint] {
    var found: [CellPoint] = []
    for direction in Direction.cardinal {
      let next = CellPoint(x: position.x + direction.stepX, y: position.y + direction.stepY)
      if next == bias.blocked {
        continue
      }
      if maze.isOpenUnseen(next, seen: seen) && !blocked(maze, next, avoidStairs: avoidStairs) {
        found.append(next)
      }
    }
    return found
  }

  private func blocked(_ maze: Maze, _ next: CellPoint, avoidStairs: Bool) -> Bool {
    if !avoidStairs {
      return false
    }
    switch maze.tile(at: next) {
    case .stairs:
      return true
    case .floor, .wall:
      return false
    }
  }

  private func pick(_ choices: [CellPoint], rng: inout SplitMix64, bias: StepBias) -> CellPoint? {
    let pool = favored(choices, bias: bias)
    if pool.isEmpty {
      return nil
    }
    let (value, generator) = rng.next()
    rng = generator
    let index = Int(value % UInt64(pool.count))
    return pool[index]
  }

  private func favored(_ choices: [CellPoint], bias: StepBias) -> [CellPoint] {
    let dry = drier(choices, avoid: bias.avoid)
    guard let lure = bias.lure else {
      return dry
    }
    return closest(dry, to: lure)
  }

  private func drier(_ choices: [CellPoint], avoid: [CellPoint]) -> [CellPoint] {
    var dry: [CellPoint] = []
    for choice in choices where !avoid.contains(choice) {
      dry.append(choice)
    }
    if dry.isEmpty {
      return choices
    }
    return dry
  }

  private func closest(_ choices: [CellPoint], to lure: CellPoint) -> [CellPoint] {
    var best: [CellPoint] = []
    var bestDistance = 0
    for choice in choices {
      let distance = abs(choice.x - lure.x) + abs(choice.y - lure.y)
      if best.isEmpty || distance < bestDistance {
        best = [choice]
        bestDistance = distance
      } else if distance == bestDistance {
        best.append(choice)
      }
    }
    return best
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
