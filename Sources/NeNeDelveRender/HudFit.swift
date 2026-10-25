enum HudFit {
  static func omitted(_ brief: HudBrief, width: Int, step: Int) -> Set<HudSlot> {
    var dropped: Set<HudSlot> = []
    if fits(brief, width, step, dropped) {
      return dropped
    }
    for slot in HudSlot.dropOrder {
      dropped.insert(slot)
      if fits(brief, width, step, dropped) {
        return dropped
      }
    }
    return dropped
  }

  private static func fits(_ brief: HudBrief, _ width: Int, _ step: Int, _ omitted: Set<HudSlot>)
    -> Bool
  {
    let read = HudRead(brief: brief, width: width, step: step, omitted: omitted)
    return HudBase.plate(read, aim: true) != nil && HudBase.plate(read, aim: false) != nil
  }
}
