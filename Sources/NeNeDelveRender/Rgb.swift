public struct Rgb: Equatable, Sendable {
  public let red: Int
  public let green: Int
  public let blue: Int

  public init(red: Int, green: Int, blue: Int) {
    self.red = Rgb.clamp(red)
    self.green = Rgb.clamp(green)
    self.blue = Rgb.clamp(blue)
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
