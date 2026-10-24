/// 起動時に合成ルートが渡すシード。1 階目の迷路はこの値そのもの。
public struct Seed: Equatable, Sendable {
  public let raw: UInt64

  public init(raw: UInt64) {
    self.raw = raw
  }

  public func forFloor(_ floor: FloorIndex) -> Seed {
    if floor.depth == 1 {
      return self
    }
    let mixed = raw &+ UInt64(floor.depth) &* 0x9E37_79B9_7F4A_7C15
    let (value, _) = SplitMix64(seed: Seed(raw: mixed)).next()
    return Seed(raw: value)
  }
}
