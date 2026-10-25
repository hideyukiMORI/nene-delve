import NeNeDelveCore

public struct HudBrief: Equatable, Sendable {
  public let clock: HudClock
  public let floor: FloorIndex
  public let look: FrameLook
  public let delver: Delver

  public init(clock: HudClock, floor: FloorIndex, look: FrameLook, delver: Delver) {
    self.clock = clock
    self.floor = floor
    self.look = look
    self.delver = delver
  }
}
