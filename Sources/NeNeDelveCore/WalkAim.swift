/// 探索を続けるか、通り過ぎた階段へ戻るか、キーで下の階へ落ちるか。
public enum WalkAim: Equatable, Sendable {
  case explore
  case recover
  case drop
}
