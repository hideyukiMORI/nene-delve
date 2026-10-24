import NeNeDelveRender

public enum AnsiDiff {
  public static func encode(previous: CellGrid?, next: CellGrid) -> String {
    if previous?.span != next.span {
      return full(next)
    }
    return rows(previous: previous, next: next)
  }

  private static func full(_ next: CellGrid) -> String {
    "\u{1b}[2J" + rows(previous: nil, next: next)
  }

  private static func rows(previous: CellGrid?, next: CellGrid) -> String {
    var text = ""
    var row = 0
    while row < next.span.height {
      text += rowText(previous: previous, next: next, row: row)
      row += 1
    }
    return text
  }

  private static func rowText(previous: CellGrid?, next: CellGrid, row: Int) -> String {
    var text = ""
    var column = 0
    while column < next.span.width {
      text += cellText(previous: previous, next: next, column: column, row: row)
      column += 1
    }
    return text
  }

  private static func cellText(previous: CellGrid?, next: CellGrid, column: Int, row: Int) -> String
  {
    let cell = next.cell(column: column, row: row)
    if let previous, previous.cell(column: column, row: row) == cell {
      return ""
    }
    return place(cell, row: row + 1, column: column + 1)
  }

  private static func place(_ cell: Cell, row: Int, column: Int) -> String {
    let foreground = color(cell.foreground, ground: 38)
    let background = color(cell.background, ground: 48)
    return "\u{1b}[\(row);\(column)H\(foreground)\(background)\(cell.glyph)"
  }

  private static func color(_ rgb: Rgb, ground: Int) -> String {
    "\u{1b}[\(ground);2;\(rgb.red);\(rgb.green);\(rgb.blue)m"
  }
}
