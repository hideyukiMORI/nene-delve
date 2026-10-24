/// 一つの壁帯。高さは画面行を垂直距離の 3 倍で割った値。
struct DepthPlane: Equatable {
  let top: Int
  let bottom: Int

  static func across(_ distance: Double, viewHeight: Int) -> DepthPlane {
    let safe = max(distance, 0.000_001)
    let lines = Int((Double(viewHeight) / (3 * safe)).rounded(.down))
    if lines <= 0 {
      let mid = viewHeight / 2
      return DepthPlane(top: mid, bottom: mid - 1)
    }
    let top = max(0, (viewHeight - lines) / 2)
    let bottom = min(viewHeight - 1, top + lines - 1)
    return DepthPlane(top: top, bottom: bottom)
  }
}
