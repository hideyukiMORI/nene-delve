import NeNeDelveCore

/// 1 フレームの色、図法、視線。
public struct FrameLook: Equatable, Sendable {
  public let theme: ThemeName
  public let view: ViewMode
  public let facing: Direction

  public init(theme: ThemeName, view: ViewMode, facing: Direction) {
    self.theme = theme
    self.view = view
    self.facing = facing
  }
}
