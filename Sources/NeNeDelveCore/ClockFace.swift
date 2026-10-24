public struct ClockFace: Equatable, Sendable {
  public let hour: Int
  public let minute: Int
  public let second: Int

  public init(hour: Int, minute: Int, second: Int) {
    self.hour = hour
    self.minute = minute
    self.second = second
  }
}
