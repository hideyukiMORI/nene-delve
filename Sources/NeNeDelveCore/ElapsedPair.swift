public struct ElapsedPair: Equatable, Sendable {
  public let totalSeconds: Int
  public let stageSeconds: Int

  public init(totalSeconds: Int, stageSeconds: Int) {
    self.totalSeconds = totalSeconds
    self.stageSeconds = stageSeconds
  }
}
