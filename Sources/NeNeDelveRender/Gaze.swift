import NeNeDelveCore

/// 1 フレームの視線。along が 0 のとき静止し、1 で次のマスの静止位置に重なる。
public struct Gaze: Equatable, Sendable {
  public let facing: Direction
  public let place: CellPoint
  public let along: Double

  public init(facing: Direction, place: CellPoint, along: Double = 0) {
    self.facing = facing
    self.place = place
    self.along = along
  }
}
