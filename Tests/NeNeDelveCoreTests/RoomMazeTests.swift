import Testing

@testable import NeNeDelveCore

struct RoomMazeTests {
  @Test func sameSeedRepeats() {
    let span = GridSpan(width: 41, height: 21)
    let first = MazeFactory.rooms(seed: Seed(raw: 7), span: span)
    let second = MazeFactory.rooms(seed: Seed(raw: 7), span: span)
    #expect(first == second)
  }

  @Test func rejectsTinySpan() {
    let plan = MazeFactory.rooms(seed: Seed(raw: 1), span: GridSpan(width: 4, height: 9))
    #expect(plan == .tooSmall)
  }

  @Test(arguments: [1, 2, 9, 40, 100, 2_048])
  func everySeedReachesTheStairs(raw: Int) {
    let spans = [
      GridSpan(width: 5, height: 5),
      GridSpan(width: 15, height: 9),
      GridSpan(width: 41, height: 21),
    ]
    for span in spans {
      let plan = MazeFactory.rooms(seed: Seed(raw: UInt64(raw)), span: span)
      guard case .maze(let maze) = plan else {
        Issue.record("expected a maze")
        return
      }
      #expect(maze.kind == .rooms)
      #expect(maze.tile(at: maze.start) == .floor)
      #expect(maze.tile(at: maze.stairs) == .stairs)
      #expect(maze.start != maze.stairs)
      #expect(reaches(maze))
    }
  }

  @Test func aWideFloorHasMoreThanOneRoom() {
    let plan = MazeFactory.rooms(seed: Seed(raw: 1), span: GridSpan(width: 41, height: 21))
    guard case .maze(let maze) = plan else {
      Issue.record("expected a maze")
      return
    }
    #expect(openCount(maze) > 40)
  }

  @Test func seedsPickEveryKind() {
    var seen: [MazeKind] = []
    var raw = 0
    while raw < 256 {
      let kind = MazeKind.chosen(Seed(raw: UInt64(raw)))
      if !seen.contains(kind) {
        seen.append(kind)
      }
      raw += 1
    }
    #expect(seen.count == MazeKind.order.count)
  }

  private func openCount(_ maze: Maze) -> Int {
    maze.tiles.filter { tile in
      switch tile {
      case .floor, .stairs:
        true
      case .wall:
        false
      }
    }.count
  }

  private func reaches(_ maze: Maze) -> Bool {
    var queue = [maze.start]
    var seen = Array(repeating: false, count: maze.span.count)
    seen[maze.span.offset(maze.start)] = true
    var cursor = 0
    while cursor < queue.count {
      if step(maze, queue: &queue, seen: &seen, cursor: cursor) {
        return true
      }
      cursor += 1
    }
    return false
  }

  private func step(_ maze: Maze, queue: inout [CellPoint], seen: inout [Bool], cursor: Int) -> Bool
  {
    let point = queue[cursor]
    if point == maze.stairs {
      return true
    }
    for direction in Direction.cardinal {
      let next = CellPoint(x: point.x + direction.stepX, y: point.y + direction.stepY)
      if !maze.span.contains(next) || seen[maze.span.offset(next)] {
        continue
      }
      switch maze.tile(at: next) {
      case .wall:
        continue
      case .floor, .stairs:
        seen[maze.span.offset(next)] = true
        queue.append(next)
      }
    }
    return false
  }
}
