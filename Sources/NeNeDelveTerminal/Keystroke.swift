public enum Keystroke: Equatable, Sendable {
  case quit
  case nextTheme
  case previousTheme
  case none

  public static func decoded(_ byte: UInt8) -> Keystroke {
    if byte == 0x03 || byte == UInt8(ascii: "q") {
      return .quit
    }
    if byte == UInt8(ascii: "t") {
      return .nextTheme
    }
    if byte == UInt8(ascii: "T") {
      return .previousTheme
    }
    return .none
  }
}
