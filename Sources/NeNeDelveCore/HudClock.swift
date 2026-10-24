/// 合成ルートが読んだ時計の写し。Core は時計を読まない。
public struct HudClock: Equatable, Sendable {
  public let elapsed: ElapsedPair
  public let date: WallDate
  public let time: ClockFace
  public let seed: Seed

  public init(elapsed: ElapsedPair, date: WallDate, time: ClockFace, seed: Seed) {
    self.elapsed = elapsed
    self.date = date
    self.time = time
    self.seed = seed
  }
}
