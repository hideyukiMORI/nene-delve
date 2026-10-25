import NeNeDelveCore

/// 1 フレームの視線。along が 0 のとき静止し、1 で次のマスの静止位置に重なる。
/// horizon が正だと消失点は上へ動き、床が広がる。0 は画面の縦中央。
public struct Gaze: Equatable, Sendable {
  public let facing: Direction
  public let place: CellPoint
  public let along: Double
  public let horizon: Int

  public init(facing: Direction, place: CellPoint, along: Double = 0, horizon: Int = 0) {
    self.facing = facing
    self.place = place
    self.along = along
    self.horizon = horizon
  }
}
