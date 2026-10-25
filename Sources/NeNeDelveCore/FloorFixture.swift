public struct FloorFixture: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case chest
    case lake
    case pit
  }

  public enum Phase: Equatable, Sendable {
    case sealed
    case bursting(Int)
    case open
  }

  public static let burstSpan = 6

  /// 水面に乗ったあとの足踏み。狭い階の一歩が読める長さ。
  public static let wadeSpan = 6

  /// 罠を踏んだあとの足踏み。
  public static let snareSpan = 4

  public let point: CellPoint
  public let kind: Kind
  public let phase: Phase

  public init(point: CellPoint, kind: Kind, phase: Phase) {
    self.point = point
    self.kind = kind
    self.phase = phase
  }
}
