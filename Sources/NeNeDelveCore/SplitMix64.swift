/// シードから次の値を作る純関数。乱数源は読まない。
public struct SplitMix64: Equatable, Sendable {
  public let state: UInt64

  public init(seed: Seed) {
    self.state = seed.raw
  }

  public func next() -> (value: UInt64, generator: SplitMix64) {
    let updated = state &+ 0x9E37_79B9_7F4A_7C15
    var mixed = updated
    mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
    mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
    let value = mixed ^ (mixed >> 31)
    return (value, SplitMix64(state: updated))
  }

  private init(state: UInt64) {
    self.state = state
  }
}
