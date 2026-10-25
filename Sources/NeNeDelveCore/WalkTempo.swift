/// 部屋の一歩だけ、すでに決まっている待ちを 112ms まで延ばす。
public enum WalkTempo {
  public static func lengthened(_ world: FloorWorld, from paced: Int) -> Int {
    if RoomSpan.crossing(world) && paced < StepPace.linger.milliseconds {
      return StepPace.linger.milliseconds
    }
    return paced
  }
}
