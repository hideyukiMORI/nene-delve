enum HudSlot: Equatable, Hashable {
  case date
  case message
  case stage
  case elapsed
  case place
  case level
  case facing
  case clock
  case view
  case vitals
  case theme
  case floor
  case seed

  static let dropOrder: [HudSlot] = [
    .date, .message, .stage, .elapsed, .place, .level, .facing, .clock, .view, .vitals, .theme,
    .floor, .seed,
  ]
}
