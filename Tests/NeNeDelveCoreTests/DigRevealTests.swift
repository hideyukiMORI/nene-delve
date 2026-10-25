import Testing

@testable import NeNeDelveCore

struct DigRevealTests {
  @Test func theSameSeedDigsInTheSameOrder() {
    for span in spans() {
      for seed in seeds() {
        for kind in bothKinds() {
          let first = carved(kind, seed: seed, span: span)
          let second = carved(kind, seed: seed, span: span)
          guard let first, let second else {
            Issue.record("expected a maze")
            return
          }
          #expect(first.dug == second.dug)
          #expect(!first.dug.isEmpty)
        }
      }
    }
  }

  @Test func theLastFrameOpensExactlyTheDugCells() {
    for sample in samples() {
      #expect(logMatches(sample))
      #expect(sample.dug.contains(sample.start))
      #expect(sample.dug.contains(sample.stairs))
      let last = DigReveal.maze(sample, frame: DigReveal.frames - 1)
      #expect(last == sample)
      #expect(DigReveal.maze(sample, frame: DigReveal.frames) == sample)
    }
  }

  @Test func eachFrameIsAPrefixOfTheNext() {
    for sample in samples() {
      var previous = DigReveal.maze(sample, frame: 0)
      #expect(previous.tile(at: sample.start) != .wall)
      #expect(openCount(previous) < openCount(sample))
      var frame = 0
      while frame < DigReveal.frames - 1 {
        let next = DigReveal.maze(sample, frame: frame + 1)
        #expect(subset(previous, next))
        previous = next
        frame += 1
      }
      #expect(previous == sample)
    }
  }

  @Test func anEmptyLogStaysOpen() {
    let span = GridSpan(width: 7, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    let stairs = CellPoint(x: 5, y: 3)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
    #expect(maze.dug.isEmpty)
    #expect(DigReveal.maze(maze, frame: 0) == maze)
  }

  @Test func ascentKeepsTheLog() {
    for sample in samples() {
      guard let point = AscentSite.point(in: sample, depth: 2) else {
        Issue.record("expected an ascent cell")
        return
      }
      let climbed = sample.withAscent(point)
      #expect(climbed.dug == sample.dug)
      #expect(climbed.dug.contains(point))
      #expect(climbed.tile(at: point) == .stairs)
    }
  }

  private func samples() -> [Maze] {
    var found: [Maze] = []
    for span in spans() {
      for seed in seeds() {
        for kind in bothKinds() {
          guard let maze = carved(kind, seed: seed, span: span) else {
            continue
          }
          found.append(maze)
        }
      }
    }
    #expect(found.count == spans().count * seeds().count * bothKinds().count)
    return found
  }

  private func spans() -> [GridSpan] {
    [
      GridSpan(width: 11, height: 9),
      GridSpan(width: 21, height: 15),
      GridSpan(width: 41, height: 21),
    ]
  }

  private func seeds() -> [UInt64] {
    [1, 9, 40]
  }

  private func bothKinds() -> [MazeKind] {
    [.filledGrid, .rooms]
  }

  private func carved(_ kind: MazeKind, seed: UInt64, span: GridSpan) -> Maze? {
    let plan = MazeFactory.make(kind: kind, seed: Seed(raw: seed), span: span)
    guard case .maze(let maze) = plan else {
      return nil
    }
    return maze
  }

  private func logMatches(_ maze: Maze) -> Bool {
    var marked = Array(repeating: false, count: maze.span.count)
    for point in maze.dug {
      if !maze.span.contains(point) {
        return false
      }
      let offset = maze.span.offset(point)
      if marked[offset] {
        return false
      }
      marked[offset] = true
    }
    var offset = 0
    while offset < maze.tiles.count {
      if opened(maze.tiles[offset]) != marked[offset] {
        return false
      }
      offset += 1
    }
    return true
  }

  private func subset(_ earlier: Maze, _ later: Maze) -> Bool {
    var offset = 0
    while offset < earlier.tiles.count {
      if opened(earlier.tiles[offset]), !opened(later.tiles[offset]) {
        return false
      }
      offset += 1
    }
    return true
  }

  private func openCount(_ maze: Maze) -> Int {
    maze.tiles.filter { tile in
      opened(tile)
    }.count
  }

  private func opened(_ tile: Tile) -> Bool {
    switch tile {
    case .wall:
      false
    case .floor, .stairs:
      true
    }
  }
}
