/// 階段の手前は短くし、行き止まりと部屋は延ばす。
public enum WalkTempo {
  public static func chosen(_ world: FloorWorld, from paced: Int) -> Int {
    if StairApproach.closing(world) && paced > StepPace.sprint.milliseconds {
      return StepPace.sprint.milliseconds
    }
    if DeadEnd.leaving(world) && paced < StepPace.wonder.milliseconds {
      return StepPace.wonder.milliseconds
    }
    if RoomSpan.crossing(world) && paced < StepPace.linger.milliseconds {
      return StepPace.linger.milliseconds
    }
    return paced
  }
}
