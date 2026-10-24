public enum ViewportFit: Equatable, Sendable {
  case maze(GridSpan)
  case tooSmall

  public static func classify(columns: Int, rows: Int, reservedRows: Int) -> ViewportFit {
    let span = GridSpan(width: columns, height: rows - reservedRows)
    if let fitted = span.fittingMaze() {
      return .maze(fitted)
    }
    return .tooSmall
  }
}
