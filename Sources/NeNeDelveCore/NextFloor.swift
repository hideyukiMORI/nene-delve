public enum NextFloor: Equatable, Sendable {
  case ready(FloorWorld)
  case stuck
}
