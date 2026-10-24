public enum ExploreMove: Equatable, Sendable {
  case moved(Explorer)
  case arrived(Explorer)
  case stuck
}
