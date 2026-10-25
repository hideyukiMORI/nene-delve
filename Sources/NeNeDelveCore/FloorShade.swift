/// 種類の次の抽選で、およそ 4 分の 1 の階を暗くする。
enum FloorShade {
  static func applied(_ maze: Maze, seed: Seed) -> Maze {
    if !dark(seed) {
      return maze
    }
    let veil = MazeVeil(shade: true, shifts: maze.veil.shifts, phase: maze.veil.phase)
    return maze.veiled(veil)
  }

  private static func dark(_ seed: Seed) -> Bool {
    let first = SplitMix64(seed: seed).next()
    let second = first.generator.next()
    return second.value.isMultiple(of: 4)
  }
}
