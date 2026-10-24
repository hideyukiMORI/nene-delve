/// 地下の階層。`B1F` が 1。表示の文言は Render が持つ。
public struct FloorIndex: Equatable, Sendable {
  public let depth: Int

  public static let first = FloorIndex(depth: 1)

  public func deeper() -> FloorIndex {
    FloorIndex(depth: depth + 1)
  }
}
