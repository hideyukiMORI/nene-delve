import NeNeDelveCore

/// 1 フレームの色、図法、視線。dug があるあいだは、その枚まで壁を開ける。
public struct FrameLook: Equatable, Sendable {
  public let theme: ThemeName
  public let view: ViewMode
  public let gaze: Gaze
  public let dug: Int?

  public init(theme: ThemeName, view: ViewMode, gaze: Gaze, dug: Int? = nil) {
    self.theme = theme
    self.view = view
    self.gaze = gaze
    self.dug = dug
  }
}
