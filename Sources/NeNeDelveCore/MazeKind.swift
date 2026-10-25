/// 迷路の種類。足すときはケースと `order` と `MazeFactory` を一緒に足す。
public enum MazeKind: Equatable, Sendable {
  case filledGrid
  case rooms
  case cavern
  case loops
  case circuit
  case racks
  case islands
  case pillars
  case spiral
  case shifting
  case blocks

  /// 抽選の順。部屋、完全迷路、洞窟、ループ、回路、ラック、島、柱、渦巻き、動く壁、街区。
  public static let order: [MazeKind] = [
    .rooms, .filledGrid, .cavern, .loops, .circuit, .racks, .islands, .pillars, .spiral, .shifting,
    .blocks,
  ]

  /// 階のシードから種類を決める。生成器自身の乱数は進まない。
  public static func chosen(_ seed: Seed) -> MazeKind {
    let (value, _) = SplitMix64(seed: seed).next()
    return order[Int(value % UInt64(order.count))]
  }
}
