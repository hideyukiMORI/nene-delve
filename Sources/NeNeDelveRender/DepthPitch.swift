/// 階が変わる途中の消失点。正の行は上へ動き、床が広がる。
public enum DepthPitch: Equatable, Sendable {
  case descend
  case ascend

  public func horizon(frame: Int) -> Int {
    let rows = frame + 1
    switch self {
    case .descend:
      return rows
    case .ascend:
      return -rows
    }
  }
}
