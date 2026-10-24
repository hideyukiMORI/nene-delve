import Testing

@testable import NeNeDelveCore

struct MazeFactoryTests {
  @Test func sameSeedRepeats() {
    let span = GridSpan(width: 15, height: 9)
    let first = MazeFactory.filled(seed: Seed(raw: 7), span: span)
    let second = MazeFactory.filled(seed: Seed(raw: 7), span: span)
    #expect(first == second)
  }

  @Test func rejectsTinySpan() {
    #expect(MazeFactory.filled(seed: Seed(raw: 1), span: GridSpan(width: 4, height: 9)) == .tooSmall)
  }

  @Test func shrinksEvenSpan() {
    let plan = MazeFactory.filled(seed: Seed(raw: 3), span: GridSpan(width: 6, height: 6))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    #expect(maze.span == GridSpan(width: 5, height: 5))
  }

  @Test(arguments: [1, 2, 9, 40, 100, 2_048])
  func everySeedReachesTheStairs(raw: Int) {
    let spans = [
      GridSpan(width: 5, height: 5),
      GridSpan(width: 15, height: 9),
      GridSpan(width: 41, height: 21),
    ]
    for span in spans {
      let plan = MazeFactory.filled(seed: Seed(raw: UInt64(raw)), span: span)
      guard case .maze(let maze) = plan else {
        Issue.record("expected a maze")
        return
      }
      #expect(maze.kind == .filledGrid)
      #expect(maze.tile(at: maze.start) == .floor)
      #expect(maze.tile(at: maze.stairs) == .stairs)
      #expect(maze.start != maze.stairs)
      #expect(passageCount(maze) == expectedPassages(maze.span))
      #expect(reaches(maze))
    }
  }

  private func passageCount(_ maze: Maze) -> Int {
    maze.tiles.filter { tile in
      switch tile {
      case .floor, .stairs:
        true
      case .wall:
        false
      }
    }.count
  }

  private func expectedPassages(_ span: GridSpan) -> Int {
    let rooms = ((span.width - 1) / 2) * ((span.height - 1) / 2)
    return rooms * 2 - 1
  }

  private func reaches(_ maze: Maze) -> Bool {
    var queue = [maze.start]
    var seen = Array(repeating: false, count: maze.span.count)
    seen[maze.span.offset(maze.start)] = true
    var cursor = 0
    while cursor < queue.count {
      if walk(maze, queue: &queue, seen: &seen, cursor: cursor) {
        return true
      }
      cursor += 1
    }
    return false
  }

  private func walk(
    _ maze: Maze,
    queue: inout [CellPoint],
    seen: inout [Bool],
    cursor: Int
  ) -> Bool {
    let point = queue[cursor]
    if point == maze.stairs {
      return true
    }
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      push(maze, next: next, queue: &queue, seen: &seen)
    }
    return false
  }

  private func push(_ maze: Maze, next: CellPoint, queue: inout [CellPoint], seen: inout [Bool]) {
    if !maze.span.contains(next) || seen[maze.span.offset(next)] {
      return
    }
    switch maze.tile(at: next) {
    case .wall:
      return
    case .floor, .stairs:
      seen[maze.span.offset(next)] = true
      queue.append(next)
    }
  }
}
