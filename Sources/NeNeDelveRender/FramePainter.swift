import NeNeDelveCore

public enum FramePainter {
  public static func paint(world: FloorWorld, clock: HudClock, theme: ThemeName, canvas: GridSpan)
    -> CellGrid
  {
    if canvas.width <= 0 || canvas.height <= 0 {
      return CellGrid(span: canvas, cells: [])
    }
    let palette = ThemePalette.palette(theme)
    var job = Job(
      palette: palette, canvas: canvas, cells: Array(repeating: palette.blank, count: canvas.count))
    job.writeLine(ScreenText.hudLine(clock, floor: world.course.floor), row: 0)
    job.writeLine(ScreenText.themeLine(theme), row: 1)
    job.writeMaze(world)
    return CellGrid(span: canvas, cells: job.cells)
  }

  private struct Job {
    let palette: ThemePalette
    let canvas: GridSpan
    var cells: [Cell]

    mutating func writeLine(_ text: String, row: Int) {
      if row < 0 || row >= canvas.height {
        return
      }
      var column = 0
      for character in text {
        if column >= canvas.width {
          return
        }
        let cell = Cell(
          glyph: character, foreground: palette.accent.hud, background: palette.ink.background)
        put(cell, at: CellPoint(x: column, y: row))
        column += 1
      }
    }

    mutating func writeMaze(_ world: FloorWorld) {
      var row = 0
      while row < world.walk.maze.span.height {
        writeMazeRow(world, row: row)
        row += 1
      }
    }

    mutating func writeMazeRow(_ world: FloorWorld, row: Int) {
      let canvasRow = row + ScreenText.hudRows
      if canvasRow >= canvas.height {
        return
      }
      var column = 0
      while column < world.walk.maze.span.width && column < canvas.width {
        let point = CellPoint(x: column, y: row)
        put(glyph(world, point: point), at: CellPoint(x: column, y: canvasRow))
        column += 1
      }
    }

    func glyph(_ world: FloorWorld, point: CellPoint) -> Cell {
      if point == world.walk.explorer.position {
        return runner()
      }
      switch world.walk.maze.tile(at: point) {
      case .wall:
        return Cell(
          glyph: ScreenText.wall, foreground: palette.ink.wall, background: palette.ink.background)
      case .floor:
        return Cell(
          glyph: ScreenText.floor, foreground: palette.ink.floor, background: palette.ink.background
        )
      case .stairs:
        return Cell(
          glyph: ScreenText.stairs, foreground: palette.accent.stairs,
          background: palette.ink.background)
      }
    }

    func runner() -> Cell {
      Cell(
        glyph: ScreenText.runner, foreground: palette.ink.runner, background: palette.ink.background
      )
    }

    mutating func put(_ cell: Cell, at point: CellPoint) {
      if canvas.contains(point) {
        cells[canvas.offset(point)] = cell
      }
    }
  }
}
