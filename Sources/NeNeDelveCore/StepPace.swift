/// 走者の速さ。描画側でフレームを間引いて速さを作らない。
public struct StepPace: Equatable, Sendable {
  public let milliseconds: Int

  public static let explore = StepPace(milliseconds: 90)
}
