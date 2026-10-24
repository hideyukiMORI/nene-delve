import NeNeDelveCore

public struct CellGrid: Equatable, Sendable {
  public let span: GridSpan
  public let cells: [Cell]

  public init(span: GridSpan, cells: [Cell]) {
    self.span = span
    self.cells = cells
  }

  public func cell(column: Int, row: Int) -> Cell {
    cells[span.offset(CellPoint(x: column, y: row))]
  }
}
