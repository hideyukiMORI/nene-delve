/// 静止時の目はマス中心より後ろ。正面の壁と左右の壁が同時に見える位置に置く。
enum DepthEye {
  static let settle = 0.46

  static func origin(_ gaze: Gaze) -> DepthCaster.Vec {
    let forward = gaze.along - settle
    let heading = DepthCaster.aim(gaze.facing)
    return DepthCaster.Vec(
      x: Double(gaze.place.x) + 0.5 + heading.x * forward,
      y: Double(gaze.place.y) + 0.5 + heading.y * forward
    )
  }
}
