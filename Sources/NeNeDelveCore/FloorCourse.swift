public struct FloorCourse: Equatable, Sendable {
  public let launchSeed: Seed
  public let floor: FloorIndex
  public let pace: StepPace
  public let delver: Delver

  public init(
    launchSeed: Seed, floor: FloorIndex, pace: StepPace, delver: Delver = .quiet
  ) {
    self.launchSeed = launchSeed
    self.floor = floor
    self.pace = pace
    self.delver = delver
  }

  public func with(delver: Delver) -> FloorCourse {
    FloorCourse(launchSeed: launchSeed, floor: floor, pace: pace, delver: delver)
  }
}
