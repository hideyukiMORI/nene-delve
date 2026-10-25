import NeNeDelveCore

enum HudSamples {
  static func values(_ read: HudRead) -> [Int] {
    let traced = read.brief.delver.trace.samples
    if traced.isEmpty {
      return [read.brief.delver.vitals.hitPoints]
    }
    return traced
  }
}
