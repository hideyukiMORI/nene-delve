enum DepthShade {
  static func glyph(_ distance: Double) -> Character {
    if distance < 1 {
      return "#"
    }
    if distance < 2 {
      return "%"
    }
    if distance < 3.5 {
      return "+"
    }
    if distance < 6 {
      return ":"
    }
    return "."
  }
}
