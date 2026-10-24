/// 迷路の種類。足すときはケースを 1 つ足す。
public enum MazeKind: Equatable, Sendable {
  case filledGrid
  case rooms

  /// 階のシードから種類を決める。生成器自身の乱数は進まない。
  public static func chosen(_ seed: Seed) -> MazeKind {
    let (value, _) = SplitMix64(seed: seed).next()
    if value.isMultiple(of: 2) {
      return .filledGrid
    }
    return .rooms
  }
}
