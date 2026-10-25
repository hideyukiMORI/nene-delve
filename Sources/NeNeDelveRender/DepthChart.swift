import NeNeDelveCore

/// 疑似 3D の右上に置く近景。正面が上、右が右手である。
enum DepthChart {
  static let reach = 3

  static func side(fitting width: Int, height: Int) -> Int {
    let room = min(width, height, reach * 2 + 1)
    if room < 3 {
      return 0
    }
    if room.isMultiple(of: 2) {
      return room - 1
    }
    return room
  }

  static func worldCell(_ chart: CellPoint, side: Int, origin: CellPoint, facing: Direction)
    -> CellPoint
  {
    let mid = side / 2
    let right = chart.x - mid
    let ahead = mid - chart.y
    let forward = moved(origin, facing, by: ahead)
    return moved(forward, turned(facing), by: right)
  }

  private static func moved(_ origin: CellPoint, _ facing: Direction, by steps: Int) -> CellPoint {
    switch facing {
    case .north:
      CellPoint(x: origin.x, y: origin.y - steps)
    case .east:
      CellPoint(x: origin.x + steps, y: origin.y)
    case .south:
      CellPoint(x: origin.x, y: origin.y + steps)
    case .west:
      CellPoint(x: origin.x - steps, y: origin.y)
    }
  }

  private static func turned(_ facing: Direction) -> Direction {
    switch facing {
    case .north:
      .east
    case .east:
      .south
    case .south:
      .west
    case .west:
      .north
    }
  }
}
