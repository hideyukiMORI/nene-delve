/// 一つの壁帯。高さは画面行を垂直距離の 3 倍で割った値。
/// horizon が正だと帯は上へ動き、床が広がる。
struct DepthPlane: Equatable {
  let top: Int
  let bottom: Int

  static func across(_ distance: Double, viewHeight: Int, horizon: Int = 0) -> DepthPlane {
    let safe = max(distance, 0.000_001)
    let lines = Int((Double(viewHeight) / (3 * safe)).rounded(.down))
    if lines <= 0 {
      let mid = viewHeight / 2 - horizon
      return DepthPlane(top: mid, bottom: mid - 1)
    }
    let shifted = (viewHeight - lines) / 2 - horizon
    let bottom = shifted + lines - 1
    return DepthPlane(
      top: min(max(shifted, 0), viewHeight),
      bottom: min(max(bottom, -1), viewHeight - 1)
    )
  }
}
