/// 平面図と、視線の奥行き。
public enum ViewMode: Equatable, Sendable {
  case plan
  case depth

  public func toggled() -> ViewMode {
    switch self {
    case .plan:
      .depth
    case .depth:
      .plan
    }
  }
}
