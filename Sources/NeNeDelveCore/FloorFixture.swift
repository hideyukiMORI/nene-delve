public struct FloorFixture: Equatable, Sendable {
  public enum Kind: Equatable, Sendable {
    case chest
  }

  public enum Phase: Equatable, Sendable {
    case sealed
    case bursting(Int)
    case open
  }

  public static let burstSpan = 6

  public let point: CellPoint
  public let kind: Kind
  public let phase: Phase

  public init(point: CellPoint, kind: Kind, phase: Phase) {
    self.point = point
    self.kind = kind
    self.phase = phase
  }
}
