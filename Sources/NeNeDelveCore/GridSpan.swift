public struct GridSpan: Equatable, Sendable {
  public let width: Int
  public let height: Int

  public init(width: Int, height: Int) {
    self.width = width
    self.height = height
  }

  public var count: Int {
    width * height
  }

  public func contains(_ point: CellPoint) -> Bool {
    point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
  }

  public func offset(_ point: CellPoint) -> Int {
    point.y * width + point.x
  }

  /// 壁と部屋が交互になる奇数の幅と高さ。5 未満は迷路にしない。
  public func fittingMaze() -> GridSpan? {
    let fittedWidth = fittedOdd(width)
    let fittedHeight = fittedOdd(height)
    if fittedWidth < 5 || fittedHeight < 5 {
      return nil
    }
    return GridSpan(width: fittedWidth, height: fittedHeight)
  }

  private func fittedOdd(_ value: Int) -> Int {
    if value < 5 {
      return value
    }
    if value.isMultiple(of: 2) {
      return value - 1
    }
    return value
  }
}
