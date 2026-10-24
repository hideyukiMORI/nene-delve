public enum LaunchParser {
  public static func parse(_ arguments: [String]) -> LaunchChoice {
    switch scan(arguments) {
    case .reject(let reason):
      .rejected(reason)
    case .done(let seed):
      choice(seed)
    }
  }

  private enum Scan: Equatable {
    case done(Seed?)
    case reject(LaunchRejection)
  }

  private enum Step: Equatable {
    case advance(Seed?, Int)
    case reject(LaunchRejection)
  }

  private static func choice(_ seed: Seed?) -> LaunchChoice {
    if let seed {
      return .seeded(seed)
    }
    return .unseeded
  }

  private static func scan(_ arguments: [String]) -> Scan {
    var index = 0
    var found: Seed?
    while index < arguments.count {
      switch one(arguments, index: index, found: found) {
      case .reject(let reason):
        return .reject(reason)
      case .advance(let seed, let next):
        found = seed
        index = next
      }
    }
    return .done(found)
  }

  private static func one(_ arguments: [String], index: Int, found: Seed?) -> Step {
    let token = arguments[index]
    if token != "--seed" && !token.hasPrefix("--seed=") {
      return .reject(.unknownOption)
    }
    if found != nil {
      return .reject(.repeated)
    }
    return readSeed(token, arguments: arguments, index: index)
  }

  private static func readSeed(_ token: String, arguments: [String], index: Int) -> Step {
    if let inline = inlineSeed(token) {
      return parsed(inline, next: index + 1)
    }
    let next = index + 1
    if next >= arguments.count {
      return .reject(.missingValue)
    }
    return parsed(arguments[next], next: next + 1)
  }

  private static func inlineSeed(_ token: String) -> String? {
    let prefix = "--seed="
    if token.hasPrefix(prefix) {
      return String(token.dropFirst(prefix.count))
    }
    return nil
  }

  private static func parsed(_ text: String, next: Int) -> Step {
    if let seed = digits(text) {
      return .advance(seed, next)
    }
    return .reject(.notAnInteger)
  }

  private static func digits(_ text: String) -> Seed? {
    if text.isEmpty {
      return nil
    }
    var value: UInt64 = 0
    for character in text {
      if let digit = digit(character) {
        if value > (UInt64.max - digit) / 10 {
          return nil
        }
        value = value * 10 + digit
      } else {
        return nil
      }
    }
    return Seed(raw: value)
  }

  private static func digit(_ character: Character) -> UInt64? {
    guard let number = character.wholeNumberValue, number <= 9 else {
      return nil
    }
    return UInt64(number)
  }
}
