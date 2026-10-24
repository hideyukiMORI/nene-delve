public struct FloorCourse: Equatable, Sendable {
  public let launchSeed: Seed
  public let floor: FloorIndex
  public let pace: StepPace

  public init(launchSeed: Seed, floor: FloorIndex, pace: StepPace) {
    self.launchSeed = launchSeed
    self.floor = floor
    self.pace = pace
  }
}
