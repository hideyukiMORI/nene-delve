/// 完全迷路の行き止まりを一つおきに開き、環を足す。
enum LoopMaze {
  static func maze(seed: Seed, span: GridSpan) -> Maze {
    var carve = CarveState(seed: seed, span: span)
    carve.digAll()
    let base = carve.maze(kind: .loops)
    return base.opening(even(Braid.caps(base)))
  }

  private static func even(_ caps: [CellPoint]) -> [CellPoint] {
    var opened: [CellPoint] = []
    var index = 0
    while index < caps.count {
      if index.isMultiple(of: 2) {
        opened.append(caps[index])
      }
      index += 1
    }
    return opened
  }
}
