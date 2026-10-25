/// 照準と雨の切替。シードと階と歩数で決まり、壁時計は読まない。
enum HudBeat: Equatable {
  case aim(Int)
  case intoRain(Int)
  case rain(Int)
  case intoAim(Int)

  static let hold = 96
  static let shift = 6

  static func phase(seed: UInt64, depth: Int, step: Int) -> HudBeat {
    let span = hold * 2 + shift * 2
    let mixed = seed &+ UInt64(depth) &* 0x9E37_79B9_7F4A_7C15
    let origin = Int(mixed % UInt64(span))
    let tick = wrapped(step + origin, span)
    if tick < hold {
      return .aim(tick)
    }
    if tick < hold + shift {
      return .intoRain(tick - hold)
    }
    if tick < hold * 2 + shift {
      return .rain(tick - hold - shift)
    }
    return .intoAim(tick - hold * 2 - shift)
  }

  static func wrapped(_ value: Int, _ span: Int) -> Int {
    let raw = value % span
    if raw < 0 {
      return raw + span
    }
    return raw
  }
}
