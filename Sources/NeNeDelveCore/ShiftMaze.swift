/// 完全迷路と、あとから一つずつ開ける壁。最初はどれも閉じている。
enum ShiftMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var carve = CarveState(seed: seed, span: span)
    carve.digAll()
    let base = carve.maze(kind: .shifting)
    let caps = Braid.caps(base)
    return base.veiled(MazeVeil(shade: false, shifts: caps, phase: caps.count))
  }
}
