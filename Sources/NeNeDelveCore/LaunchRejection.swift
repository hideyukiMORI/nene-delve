public enum LaunchRejection: Equatable, Sendable {
  case missingValue
  case notAnInteger
  case repeated
  case unknownOption
}
