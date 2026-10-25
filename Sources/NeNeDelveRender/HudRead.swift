struct HudRead: Equatable {
  let brief: HudBrief
  let width: Int
  let step: Int
  let omitted: Set<HudSlot>
}
