/// 欄か、空きか、図か。雨は欄と、その両隣には落とさない。
enum HudKind: Equatable {
  case text
  case blank
  case frame
  case spark
  case gauge
  case live
  case lost
  case dead
}
