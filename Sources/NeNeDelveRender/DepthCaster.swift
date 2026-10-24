import NeNeDelveCore

enum DepthCaster {
  struct Vec: Equatable {
    let x: Double
    let y: Double
  }

  struct Cast: Equatable {
    let maze: Maze
    let origin: Vec
    let facing: Direction
  }

  static func columns(_ cast: Cast, count: Int) -> [DepthHit] {
    var hits: [DepthHit] = []
    var index = 0
    while index < count {
      hits.append(column(cast, index: index, count: count))
      index += 1
    }
    return hits
  }

  static func camera(_ index: Int, count: Int) -> Double {
    if count <= 0 {
      return 0
    }
    return 2 * Double(index) / Double(count) - 1
  }

  static func aim(_ facing: Direction) -> Vec {
    switch facing {
    case .north:
      Vec(x: 0, y: -1)
    case .east:
      Vec(x: 1, y: 0)
    case .south:
      Vec(x: 0, y: 1)
    case .west:
      Vec(x: -1, y: 0)
    }
  }

  static func plane(_ aim: Vec) -> Vec {
    Vec(x: -aim.y * 0.7, y: aim.x * 0.7)
  }

  private struct Stride {
    let stepX: Int
    let stepY: Int
    let deltaX: Double
    let deltaY: Double
  }

  private struct Cursor {
    var mapX: Int
    var mapY: Int
    var sideX: Double
    var sideY: Double
  }

  private static func column(_ cast: Cast, index: Int, count: Int) -> DepthHit {
    let heading = aim(cast.facing)
    let skew = plane(heading)
    let offset = camera(index, count: count)
    let dirX = heading.x + skew.x * offset
    let dirY = heading.y + skew.y * offset
    return march(cast.maze, from: cast.origin, dirX: dirX, dirY: dirY)
  }

  private static func march(_ maze: Maze, from: Vec, dirX: Double, dirY: Double) -> DepthHit {
    let pace = stride(dirX, dirY)
    var cursor = cursor(from, dirX: dirX, dirY: dirY, stride: pace)
    let found = walk(maze, cursor: &cursor, stride: pace)
    let distance = found.vertical ? cursor.sideX - pace.deltaX : cursor.sideY - pace.deltaY
    return DepthHit(distance: max(distance, 0.05), tile: found.tile, vertical: found.vertical)
  }

  private static func stride(_ dirX: Double, _ dirY: Double) -> Stride {
    Stride(
      stepX: dirX < 0 ? -1 : 1,
      stepY: dirY < 0 ? -1 : 1,
      deltaX: dirX == 0 ? 1e30 : abs(1 / dirX),
      deltaY: dirY == 0 ? 1e30 : abs(1 / dirY)
    )
  }

  private static func cursor(_ origin: Vec, dirX: Double, dirY: Double, stride: Stride) -> Cursor {
    let mapX = Int(origin.x.rounded(.down))
    let mapY = Int(origin.y.rounded(.down))
    return Cursor(
      mapX: mapX,
      mapY: mapY,
      sideX: sideStart(dirX, pos: origin.x, map: mapX, delta: stride.deltaX),
      sideY: sideStart(dirY, pos: origin.y, map: mapY, delta: stride.deltaY)
    )
  }

  private static func sideStart(_ dir: Double, pos: Double, map: Int, delta: Double) -> Double {
    if dir < 0 {
      return (pos - Double(map)) * delta
    }
    return (Double(map) + 1 - pos) * delta
  }

  private static func walk(_ maze: Maze, cursor: inout Cursor, stride: Stride) -> DepthHit {
    var vertical = false
    var left = maze.span.count
    while left > 0 {
      vertical = step(&cursor, stride)
      if halted(maze, cursor.mapX, mapY: cursor.mapY) {
        return DepthHit(
          distance: 0, tile: tile(maze, cursor.mapX, mapY: cursor.mapY), vertical: vertical)
      }
      left -= 1
    }
    return DepthHit(distance: 0, tile: .wall, vertical: vertical)
  }

  private static func step(_ cursor: inout Cursor, _ stride: Stride) -> Bool {
    if cursor.sideX < cursor.sideY {
      cursor.sideX += stride.deltaX
      cursor.mapX += stride.stepX
      return true
    }
    cursor.sideY += stride.deltaY
    cursor.mapY += stride.stepY
    return false
  }

  private static func halted(_ maze: Maze, _ column: Int, mapY: Int) -> Bool {
    let point = CellPoint(x: column, y: mapY)
    if !maze.span.contains(point) {
      return true
    }
    switch maze.tile(at: point) {
    case .wall, .stairs:
      return true
    case .floor:
      return false
    }
  }

  private static func tile(_ maze: Maze, _ column: Int, mapY: Int) -> Tile {
    let point = CellPoint(x: column, y: mapY)
    if !maze.span.contains(point) {
      return .wall
    }
    return maze.tile(at: point)
  }
}
