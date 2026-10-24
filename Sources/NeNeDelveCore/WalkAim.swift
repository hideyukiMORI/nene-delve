/// 探索を続けるか、通り過ぎた階段へ戻るか。
public enum WalkAim: Equatable, Sendable {
  case explore
  case recover
}
