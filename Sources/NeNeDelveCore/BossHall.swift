/// 10 階ごとの大部屋。仕掛けを置いたあとに、壁だけを床へ開ける。
public enum BossHall {
  public struct Opening: Equatable, Sendable {
    public let maze: Maze
    public let stand: CellPoint?
  }

  public static func hosts(_ depth: Int) -> Bool {
    depth >= 10 && depth.isMultiple(of: 10)
  }

  public static func carve(_ maze: Maze, depth: Int) -> Opening {
    if !hosts(depth) {
      return Opening(maze: maze, stand: nil)
    }
    let room = rectangle(maze.span)
    let fresh = walls(in: maze, room: room)
    if fresh.isEmpty {
      return Opening(maze: maze, stand: nil)
    }
    return Opening(maze: maze.opening(fresh), stand: nearest(fresh, room: room))
  }

  private struct Rect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
  }

  private static func rectangle(_ span: GridSpan) -> Rect {
    let width = min(span.width - 2, max(9, span.width * 2 / 3))
    let height = min(span.height - 2, max(7, span.height * 2 / 3))
    let x = 1 + (span.width - 2 - width) / 2
    let y = 1 + (span.height - 2 - height) / 2
    return Rect(x: x, y: y, width: width, height: height)
  }

  private static func walls(in maze: Maze, room: Rect) -> [CellPoint] {
    var fresh: [CellPoint] = []
    var y = room.y
    while y < room.y + room.height {
      var x = room.x
      while x < room.x + room.width {
        let point = CellPoint(x: x, y: y)
        switch maze.tile(at: point) {
        case .wall:
          fresh.append(point)
        case .floor, .stairs:
          break
        }
        x += 1
      }
      y += 1
    }
    return fresh
  }

  private static func nearest(_ fresh: [CellPoint], room: Rect) -> CellPoint {
    let centerX = room.x + room.width / 2
    let centerY = room.y + room.height / 2
    var best = fresh[0]
    var bestDistance = distance(best, x: centerX, y: centerY)
    for point in fresh {
      let next = distance(point, x: centerX, y: centerY)
      if next < bestDistance {
        best = point
        bestDistance = next
      }
    }
    return best
  }

  private static func distance(_ point: CellPoint, x: Int, y: Int) -> Int {
    abs(point.x - x) + abs(point.y - y)
  }
}
