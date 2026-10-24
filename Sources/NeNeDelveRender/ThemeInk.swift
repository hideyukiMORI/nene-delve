public struct ThemeInk: Equatable, Sendable {
  public let background: Rgb
  public let wall: Rgb
  public let floor: Rgb
  public let runner: Rgb

  public init(background: Rgb, wall: Rgb, floor: Rgb, runner: Rgb) {
    self.background = background
    self.wall = wall
    self.floor = floor
    self.runner = runner
  }
}
