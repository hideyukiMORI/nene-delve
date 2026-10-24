public enum Direction: Equatable, Sendable {
  case north
  case east
  case south
  case west

  static let cardinal: [Direction] = [.north, .east, .south, .west]

  var stepX: Int {
    switch self {
    case .north, .south:
      0
    case .east:
      1
    case .west:
      -1
    }
  }

  var stepY: Int {
    switch self {
    case .east, .west:
      0
    case .north:
      -1
    case .south:
      1
    }
  }
}
