public struct Rgb: Equatable, Sendable {
  public let red: Int
  public let green: Int
  public let blue: Int

  public init(red: Int, green: Int, blue: Int) {
    self.red = Rgb.clamp(red)
    self.green = Rgb.clamp(green)
    self.blue = Rgb.clamp(blue)
  }

  public func dimmed(_ percent: Int) -> Rgb {
    let scale = min(max(percent, 0), 100)
    return Rgb(red: red * scale / 100, green: green * scale / 100, blue: blue * scale / 100)
  }

  private static func clamp(_ value: Int) -> Int {
    if value < 0 {
      return 0
    }
    if value > 255 {
      return 255
    }
    return value
  }
}
