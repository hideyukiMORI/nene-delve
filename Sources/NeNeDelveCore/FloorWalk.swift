public struct FloorWalk: Equatable, Sendable {
  public let maze: Maze
  public let explorer: Explorer
  public let rng: SplitMix64
  public let steps: Int

  public init(maze: Maze, explorer: Explorer, rng: SplitMix64, steps: Int) {
    self.maze = maze
    self.explorer = explorer
    self.rng = rng
    self.steps = steps
  }
}
