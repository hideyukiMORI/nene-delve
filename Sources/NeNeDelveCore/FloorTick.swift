public enum FloorTick: Equatable, Sendable {
  case running(FloorWorld)
  case descended(FloorWorld)
  case stuck
}
