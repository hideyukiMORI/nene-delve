enum HudJoin {
  static func pieces(_ parts: [[HudCell]], gap: Int) -> [HudCell] {
    var joined: [HudCell] = []
    var started = false
    for part in parts where !part.isEmpty {
      if started {
        joined.append(contentsOf: HudCell.spaces(gap))
      }
      joined.append(contentsOf: part)
      started = true
    }
    return joined
  }
}
