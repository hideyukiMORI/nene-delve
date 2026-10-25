/// 走者の速さ。描画側でフレームを間引いて速さを作らない。
public struct StepPace: Equatable, Sendable {
  public let milliseconds: Int

  /// 狭い階の一歩。
  public static let explore = StepPace(milliseconds: 80)

  /// 広い階でも、セルを目で追える短さで止める。
  public static let rush = StepPace(milliseconds: 28)

  /// 同じ方向へ続く一歩。階の歩調には使わない。
  public static let dash = StepPace(milliseconds: 14)

  /// 部屋の中の一歩。階の歩調には使わず、それより長い待ちは縮めない。
  public static let linger = StepPace(milliseconds: 112)

  /// 広い階ほど短くする。だいたい数十秒で階を歩き切る間隔に寄せる。
  public static func forSpan(_ span: GridSpan) -> StepPace {
    let steps = max(span.count, 1)
    let raw = 36_000 / steps
    if raw < rush.milliseconds {
      return rush
    }
    if raw > explore.milliseconds {
      return explore
    }
    return StepPace(milliseconds: raw)
  }
}
