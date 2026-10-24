public enum ThemeName: Equatable, Sendable {
  case neonGrid
  case phosphor
  case amberTerm
  case iceCore
  case synthwave
  case deepSea
  case void
  case toxic
  case aurora
  case carbon

  public func next() -> ThemeName {
    switch self {
    case .neonGrid:
      .phosphor
    case .phosphor:
      .amberTerm
    case .amberTerm:
      .iceCore
    case .iceCore:
      .synthwave
    case .synthwave:
      .deepSea
    case .deepSea:
      .void
    case .void:
      .toxic
    case .toxic:
      .aurora
    case .aurora:
      .carbon
    case .carbon:
      .neonGrid
    }
  }

  public func previous() -> ThemeName {
    switch self {
    case .neonGrid:
      .carbon
    case .phosphor:
      .neonGrid
    case .amberTerm:
      .phosphor
    case .iceCore:
      .amberTerm
    case .synthwave:
      .iceCore
    case .deepSea:
      .synthwave
    case .void:
      .deepSea
    case .toxic:
      .void
    case .aurora:
      .toxic
    case .carbon:
      .aurora
    }
  }
}
