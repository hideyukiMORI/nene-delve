enum HudHash {
  static let rain = Array(
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz._/^\\#:-|=+()<>")

  static func mix(column: Int, row: Int, time: Int) -> UInt32 {
    var hash = UInt32(truncatingIfNeeded: column) &* 73_856_093
    hash ^= UInt32(truncatingIfNeeded: row) &* 19_349_663
    hash ^= UInt32(truncatingIfNeeded: time) &* 83_492_791
    hash ^= 0x5BD1_E995
    hash = (hash ^ (hash >> 15)) &* 0x2C1B_3C6D
    hash = (hash ^ (hash >> 12)) &* 0x297A_2D39
    return hash ^ (hash >> 15)
  }

  static func glyph(column: Int, row: Int, time: Int) -> Character {
    rain[Int(mix(column: column, row: row, time: time) % UInt32(rain.count))]
  }
}
