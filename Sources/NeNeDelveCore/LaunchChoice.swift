public enum LaunchChoice: Equatable, Sendable {
  case seeded(Seed)
  case unseeded
  case rejected(LaunchRejection)
}
