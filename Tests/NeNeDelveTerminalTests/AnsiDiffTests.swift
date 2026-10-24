import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender
@testable import NeNeDelveTerminal

struct AnsiDiffTests {
  @Test func identicalFramesEncodeNothing() {
    let grid = sample()
    #expect(AnsiDiff.encode(previous: grid, next: grid).isEmpty)
  }

  @Test func theFirstFrameClearsAndPlacesTheGlyph() {
    let grid = sample()
    let text = AnsiDiff.encode(previous: nil, next: grid)
    #expect(text.contains("\u{1b}[2J"))
    #expect(text.contains("@"))
    #expect(text.contains("38;2;255;0;255"))
  }

  @Test func aChangedCellIsTheOnlyGlyph() {
    let grid = sample()
    var cells = grid.cells
    cells[1] = Cell(glyph: "?", foreground: Rgb(red: 1, green: 2, blue: 3), background: Rgb(red: 0, green: 0, blue: 0))
    let next = CellGrid(span: grid.span, cells: cells)
    let text = AnsiDiff.encode(previous: grid, next: next)
    #expect(text.contains("?"))
    #expect(!text.contains("@"))
  }

  private func sample() -> CellGrid {
    let span = GridSpan(width: 2, height: 1)
    let cells = [
      Cell(glyph: "#", foreground: Rgb(red: 0, green: 255, blue: 255), background: Rgb(red: 0, green: 0, blue: 0)),
      Cell(glyph: "@", foreground: Rgb(red: 255, green: 0, blue: 255), background: Rgb(red: 0, green: 0, blue: 0)),
    ]
    return CellGrid(span: span, cells: cells)
  }
}
